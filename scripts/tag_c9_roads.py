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

# Disjoint way ID offset prevents overlapping official OsmAnd NL maps from shadowing BromBrom ways.
# shortcut: assumes upstream OSM way IDs stay below 40B (currently ~1.6B); raise offset if OSM ever nears 40B.
WAY_ID_OFFSET = 50_000_000_000
SPLIT_WAY_ID_START = 90_000_000_000
BROMBROM_TAG_KEY = "cemt"
BROMBROM_TAG_VAL = "brombrom"


class TagC9Handler(osmium.SimpleHandler):
    def __init__(self, writer, forbidden_ways, way_snaps, exemption_ways=None, via_way_ids=None):
        super().__init__()
        self.writer = writer
        self.forbidden_ways = forbidden_ways
        self.way_snaps = way_snaps
        self.exemption_ways = exemption_ways or set()
        self.via_way_ids = via_way_ids or set()
        self.next_way_id = SPLIT_WAY_ID_START
        self.pending_split_ways = []
        self.split_ways = {}
        self.via_way_endpoints = {}
        self._split_flushed = False

    def flush_split_ways(self):
        if self._split_flushed:
            return
        self._split_flushed = True
        for b_id, nodes_b, tags_b in self.pending_split_ways:
            self.writer.add_way(osmium.osm.mutable.Way(id=b_id, nodes=nodes_b, tags=tags_b))
        self.pending_split_ways.clear()

    def node(self, n):
        self.writer.add_node(n)

    def relation(self, r):
        self.flush_split_ways()
        if not any(m.type == 'w' for m in r.members):
            self.writer.add_relation(r)
            return

        anchor_nodes = {m.ref for m in r.members if m.type == 'n' and m.role == 'via'}
        for m in r.members:
            if m.type == 'w' and m.role == 'via':
                if m.ref in self.via_way_endpoints:
                    anchor_nodes.update(self.via_way_endpoints[m.ref])

        new_members = []
        for m in r.members:
            if m.type != 'w':
                new_members.append((m.type, m.ref, m.role))
                continue
            if m.ref in self.split_ways:
                nodes_a, id_a, nodes_b, id_b = self.split_ways[m.ref]
                if (anchor_nodes & nodes_b) and not (anchor_nodes & nodes_a):
                    new_members.append(('w', id_b, m.role))
                else:
                    new_members.append(('w', id_a, m.role))
            else:
                new_members.append(('w', m.ref + WAY_ID_OFFSET, m.role))
        self.writer.add_relation(r.replace(members=new_members))

    def way(self, w):
        way_id = int(w.id)
        offset_id = way_id + WAY_ID_OFFSET
        is_forbidden = way_id in self.forbidden_ways
        is_ndw_exempted = way_id in self.exemption_ways

        if way_id in self.via_way_ids and len(w.nodes) >= 2:
            self.via_way_endpoints[way_id] = (w.nodes[0].ref, w.nodes[-1].ref)

        # Microcar allowances: NDW snapped exemptions (OB65) or explicit OSM microcar=yes
        # (including explicitly permitted G12a/G11 cycleways/paths like Kiltunnelweg, but never pedestrian/equestrian/stairs)
        has_microcar_no = (w.tags.get('microcar') == 'no' and w.tags.get('motor_vehicle') != 'no')
        is_never_microcar_path = w.tags.get('highway') in ('footway', 'pedestrian', 'bridleway', 'steps')
        has_microcar_yes = is_ndw_exempted or (w.tags.get('microcar') == 'yes' and not is_never_microcar_path)
        strip_invalid_path_microcar = is_never_microcar_path and not is_ndw_exempted and w.tags.get('microcar') == 'yes'

        tags = dict(w.tags)
        tags[BROMBROM_TAG_KEY] = BROMBROM_TAG_VAL

        if not is_forbidden and not has_microcar_no and not has_microcar_yes and not strip_invalid_path_microcar:
            self.writer.add_way(w.replace(id=offset_id, tags=tags))
            return

        # Strip stray raw OSM microcar=yes on footways/pedestrian/bridleway/steps so it cannot bypass routing.xml
        if strip_invalid_path_microcar:
            tags.pop('microcar', None)

        # 0. Allow microcar=yes overrides by bypassing general motor_vehicle/vehicle/access/motorcar prohibitions
        if has_microcar_yes and not is_forbidden:
            for tag in ['motor_vehicle', 'vehicle', 'access', 'motorcar']:
                tags[tag] = 'yes'
            tags['microcar'] = 'yes'

        # 1. Existing OSM Coverage: Promote 'microcar=no' to 'motor_vehicle=no'
        # This ensures OsmAnd (which mainly looks at motor_vehicle) respects these.
        if has_microcar_no:
            tags['motor_vehicle'] = 'no'

        # 2. NDW Pipeline Coverage: Tag/split ways identified as C9-forbidden
        if is_forbidden:
            snaps = self.way_snaps.get(way_id, [])
            split_done = False

            # Never split restriction via-ways (multi-way via ordering depends on traversal direction)
            if snaps and len(w.nodes) >= 3 and way_id not in self.via_way_ids:
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
                    split_idx, _ = min(
                        enumerate(coords),
                        key=lambda item: ((item[1][0] - snap_lon) * factor_x) ** 2 + ((item[1][1] - snap_lat) * factor_y) ** 2
                    )

                    # Calculate distances from closest node to start/end
                    dist_to_start = distance_meters(coords[split_idx][0], coords[split_idx][1], coords[0][0], coords[0][1])
                    dist_to_end = distance_meters(coords[split_idx][0], coords[split_idx][1], coords[-1][0], coords[-1][1])

                    # Only split if closest node is not near start or end
                    if dist_to_start >= 5.0 and dist_to_end >= 5.0:
                        nodes_A = [n.ref for n in node_list[:split_idx + 1]]
                        nodes_B = [n.ref for n in node_list[split_idx:]]

                        # Determine directionality
                        p_split = Point(coords[split_idx])
                        p_next = Point(coords[split_idx + 1])
                        bearing_B = bearing_between(p_split, p_next)

                        # Convert mathematical segment bearing to geographical bearing
                        seg_geo_bearing = (90 - bearing_B) % 360

                        # Calculate angle difference
                        restrict_B = True
                        if bearing_sign is not None:
                            diff = min(abs(bearing_sign - seg_geo_bearing), 360 - abs(bearing_sign - seg_geo_bearing))
                            restrict_B = diff < 90.0

                        print(f"Way {way_id} ('{tags.get('name')}') split at node {node_list[split_idx].ref} (ratio {split_idx/len(node_list):.2f}). Restricting Way {'B' if restrict_B else 'A'}.")

                        tags_A = tags.copy()
                        tags_B = tags.copy()

                        if restrict_B:
                            tags_B['motor_vehicle'] = 'no'
                            tags_B['microcar'] = 'no'
                        else:
                            tags_A['motor_vehicle'] = 'no'
                            tags_A['microcar'] = 'no'

                        b_id = self.next_way_id
                        self.next_way_id += 1

                        self.writer.add_way(w.replace(id=offset_id, nodes=nodes_A, tags=tags_A))
                        self.pending_split_ways.append((b_id, nodes_B, tags_B))
                        self.split_ways[way_id] = (set(nodes_A), offset_id, set(nodes_B), b_id)
                        split_done = True
                        break # Only split once

            if not split_done:
                tags['motor_vehicle'] = 'no'
                tags['microcar'] = 'no'
                self.writer.add_way(w.replace(id=offset_id, tags=tags))
        else:
            self.writer.add_way(w.replace(id=offset_id, tags=tags))


class _ViaWayCollector(osmium.SimpleHandler):
    def __init__(self):
        super().__init__()
        self.via_way_ids = set()

    def relation(self, r):
        for m in r.members:
            if m.type == 'w' and m.role == 'via':
                self.via_way_ids.add(m.ref)

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

    # Load microcar exemption ways snapped from NDW (G12a/G11/C12/C9 exemptions)
    exemption_ways = set()
    if os.path.exists("g_exemptions_ways.json"):
        try:
            with open("g_exemptions_ways.json", "r") as f:
                exemption_ways = set(json.load(f))
            overlap = exemption_ways & forbidden_ways
            if overlap:
                print(f"Warning: {len(overlap)} ways appear in both g_exemptions_ways.json and forbidden_ways; keeping forbidden.")
                exemption_ways -= overlap
            print(f"Loaded {len(exemption_ways)} microcar exemption ways from g_exemptions_ways.json")
        except Exception as e:
            print(f"Warning loading g_exemptions_ways.json: {e}")

    print("Scanning restriction via-ways...")
    via_collector = _ViaWayCollector()
    via_collector.apply_file("nl_roads.osm.pbf")

    print("Tagging OSM PBF...")
    with osmium.SimpleWriter("NL_BromBrom_tagged.osm.pbf", overwrite=True) as writer:
        handler = TagC9Handler(writer, forbidden_ways, way_snaps, exemption_ways, via_way_ids=via_collector.via_way_ids)
        # Optimization: Use the filtered roads-only PBF as base (huge RAM saving) and cache locations
        handler.apply_file("nl_roads.osm.pbf", locations=True)
        handler.flush_split_ways()
    print(f"✓ NL_BromBrom_tagged.osm.pbf created ({len(forbidden_ways)} C9 ways processed)")

if __name__ == "__main__":
    main()
