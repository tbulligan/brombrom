import geopandas as gpd
import pandas as pd
import os
import osmium
import math
import json
from shapely.geometry import Point

try:
    from snap_c9_to_roads import bearing_between
    import build_config as config
except ImportError:
    from scripts.snap_c9_to_roads import bearing_between
    from scripts import build_config as config

def distance_meters(lon1, lat1, lon2, lat2):
    # Flat-Earth equirectangular approximation for speed in local node checks. Max ceiling error increases over large distances.
    lat_avg = math.radians((lat1 + lat2) / 2.0)
    dx = (lon2 - lon1) * 111320.0 * math.cos(lat_avg)
    dy = (lat2 - lat1) * 111320.0
    return math.sqrt(dx*dx + dy*dy)

class TagC9Handler(osmium.SimpleHandler):
    def __init__(self, writer, forbidden_ways, way_snaps):
        super().__init__()
        self.writer = writer
        self.forbidden_ways = forbidden_ways
        self.way_snaps = way_snaps
        # Hardcoded ID offset to generate unique synthetic ways. Collision ceiling at 90B+ upstream OSM IDs.
        self.next_way_id = 90000000000

    def node(self, n):
        # Forward all nodes unchanged
        self.writer.add_node(n)

    def relation(self, r):
        # Forward all relations unchanged
        self.writer.add_relation(r)

    def way(self, w):
        way_id = int(w.id)
        is_forbidden = way_id in self.forbidden_ways
        
        # Fast path check using native C++ key lookup (no dict copying) (Task 3 optimization)
        has_microcar_no = (w.tags.get('microcar') == 'no' and w.tags.get('motor_vehicle') != 'no')
        has_microcar_yes = (w.tags.get('microcar') == 'yes')
        
        if not is_forbidden and not has_microcar_no and not has_microcar_yes:
            self.writer.add_way(w)
            return

        tags = dict(w.tags)
        modified = False
        
        # 0. Allow microcar=yes overrides by bypassing general motor_vehicle/vehicle/access/motorcar prohibitions
        if has_microcar_yes and not is_forbidden:
            for tag in ['motor_vehicle', 'vehicle', 'access', 'motorcar']:
                if tags.get(tag) != 'yes':
                    tags[tag] = 'yes'
                    modified = True
        
        # 1. Existing OSM Coverage: Promote 'microcar=no' to 'motor_vehicle=no'
        # This ensures OsmAnd (which mainly looks at motor_vehicle) respects these.
        if has_microcar_no:
            tags['motor_vehicle'] = 'no'
            modified = True

        # 2. NDW Pipeline Coverage: Tag/split ways identified as C9-forbidden
        if is_forbidden:
            snaps = self.way_snaps.get(way_id, [])
            split_done = False
            
            if snaps and len(w.nodes) >= 3:
                node_list = list(w.nodes)
                coords = [(n.lon, n.lat) for n in node_list]
                
                # Check for snaps in the middle
                for snap in snaps:
                    snap_lon = snap['lon']
                    snap_lat = snap['lat']
                    bearing_sign = snap['bearing']
                    
                    # Find closest node
                    cos_lat = math.cos(math.radians(snap_lat))
                    factor_x = 111320.0 * cos_lat
                    factor_y = 111320.0
                    split_idx, (n_lon, n_lat) = min(
                        enumerate(coords),
                        key=lambda item: ((item[1][0] - snap_lon) * factor_x) ** 2 + ((item[1][1] - snap_lat) * factor_y) ** 2
                    )
                    min_dist = ((n_lon - snap_lon) * factor_x) ** 2 + ((n_lat - snap_lat) * factor_y) ** 2
                            
                    # Calculate distances from closest node to start/end
                    dist_to_start = distance_meters(coords[split_idx][0], coords[split_idx][1], coords[0][0], coords[0][1])
                    dist_to_end = distance_meters(coords[split_idx][0], coords[split_idx][1], coords[-1][0], coords[-1][1])
                    
                    # Only split if closest node is not near start or end
                    if dist_to_start >= 5.0 and dist_to_end >= 5.0:
                        # Split way!
                        nodes_A = [n.ref for n in node_list[:split_idx + 1]]
                        nodes_B = [n.ref for n in node_list[split_idx:]]
                        
                        # Determine directionality
                        # Calculate bearing of segment B
                        p_split = Point(coords[split_idx])
                        p_next = Point(coords[split_idx + 1])
                        bearing_B = bearing_between(p_split, p_next)
                        
                        # Convert mathematical segment bearing to geographical bearing
                        seg_geo_bearing = (90 - bearing_B) % 360
                        
                        # Calculate angle difference
                        restrict_B = True # Default if bearing is missing
                        if bearing_sign is not None:
                            diff = min(abs(bearing_sign - seg_geo_bearing), 360 - abs(bearing_sign - seg_geo_bearing))
                            # If difference is < 90 degrees, the sign applies in the direction of B
                            if diff < 90.0:
                                restrict_B = True
                            else:
                                restrict_B = False
                                
                        # Print debug info
                        print(f"Way {way_id} ('{tags.get('name')}') split at node {node_list[split_idx].ref} (ratio {split_idx/len(node_list):.2f}). Restricting Way {'B' if restrict_B else 'A'}.")
                        
                        tags_A = tags.copy()
                        tags_B = tags.copy()
                        
                        if restrict_B:
                            tags_B['motor_vehicle'] = 'no'
                            tags_B['microcar'] = 'no'
                        else:
                            tags_A['motor_vehicle'] = 'no'
                            tags_A['microcar'] = 'no'
                            
                        w_A = w.replace(nodes=nodes_A, tags=tags_A)
                        w_B = w.replace(id=self.next_way_id, nodes=nodes_B, tags=tags_B)
                        self.next_way_id += 1
                        
                        self.writer.add_way(w_A)
                        self.writer.add_way(w_B)
                        split_done = True
                        break # Only split once
            
            if not split_done:
                if tags.get('motor_vehicle') != 'no' or tags.get('microcar') != 'no':
                    tags['motor_vehicle'] = 'no'
                    tags['microcar'] = 'no'
                    modified = True
                w = w.replace(tags=tags)
                self.writer.add_way(w)
        else:
            if modified:
                w = w.replace(tags=tags)
            self.writer.add_way(w)

def main():
    if os.path.exists("Netherlands.osm.pbf"):
        print("Netherlands.osm.pbf already exists. Skipping.")
        return

    gdf = gpd.read_file("nl_roads_brom.gpkg")
    print(f"Loaded {len(gdf)} C9-forbidden roads")

    forbidden_ways = set()
    id_field = config.find_osm_id_field(gdf)
    if id_field:
        forbidden_ways = set(gdf[id_field].dropna().astype(int).unique())
        print(f"Using '{id_field}' with {len(forbidden_ways)} unique ways")

    if not forbidden_ways:
        raise ValueError("No valid OSM ID field found")

    # Load snaps detail mapping
    way_snaps = {}
    if 'c9_snaps' in gdf.columns:
        # Task 2 optimization: Use zip over columns for fast iteration instead of iterrows
        for oid, snaps_str in zip(gdf[id_field].values, gdf['c9_snaps'].values):
            if pd.isna(oid):
                continue
            if snaps_str and not pd.isna(snaps_str):
                try:
                    way_snaps[int(oid)] = json.loads(snaps_str)
                except Exception:
                    pass

    print("Tagging OSM PBF...")
    with osmium.SimpleWriter("Netherlands.osm.pbf", overwrite=True) as writer:
        handler = TagC9Handler(writer, forbidden_ways, way_snaps)
        # Optimization: Use the filtered roads-only PBF as base (huge RAM saving) and cache locations
        handler.apply_file("nl_roads.osm.pbf", locations=True)
    print(f"✓ Netherlands.osm.pbf created ({len(forbidden_ways)} C9 ways processed)")

if __name__ == "__main__":
    main()
