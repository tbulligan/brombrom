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
        has_microcar_yes = (w.tags.get('microcar') == 'yes' and (w.tags.get('motor_vehicle') == 'no' or w.tags.get('vehicle') == 'no' or w.tags.get('access') == 'no' or w.tags.get('motorcar') == 'no'))
        
        if not is_forbidden and not has_microcar_no and not has_microcar_yes:
            self.writer.add_way(w)
            return

        tags = dict(w.tags)
        modified = False
        
        # 0. Allow microcar=yes overrides by bypassing general motor_vehicle/vehicle/access/motorcar prohibitions
        if has_microcar_yes and not is_forbidden:
            for tag in ['motor_vehicle', 'vehicle', 'access', 'motorcar']:
                if tags.get(tag) == 'no':
                    tags[tag] = 'yes'
                    modified = True
        
        # 1. Existing OSM Coverage: Promote 'microcar=no' to 'motor_vehicle=no'
        # This ensures OsmAnd (which mainly looks at motor_vehicle) respects these.
        if has_microcar_no:
            tags['motor_vehicle'] = 'no'
            modified = True

        # 2. NDW Pipeline Coverage: Tag ways identified as C9-forbidden
        if is_forbidden:
            if tags.get('motor_vehicle') != 'no' or tags.get('microcar') != 'no':
                tags['motor_vehicle'] = 'no'
                tags['microcar'] = 'no'
                modified = True

        if modified:
            w = w.replace(tags=tags)
        self.writer.add_way(w)

def main():
    if os.path.exists("NL_BromBrom_tagged.osm.pbf"):
        print("NL_BromBrom_tagged.osm.pbf already exists. Skipping.")
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
    with osmium.SimpleWriter("NL_BromBrom_tagged.osm.pbf", overwrite=True) as writer:
        handler = TagC9Handler(writer, forbidden_ways, way_snaps)
        # Optimization: Use the filtered roads-only PBF as base (huge RAM saving) and cache locations
        handler.apply_file("nl_roads.osm.pbf", locations=True)
    print(f"✓ NL_BromBrom_tagged.osm.pbf created ({len(forbidden_ways)} C9 ways processed)")

if __name__ == "__main__":
    main()
