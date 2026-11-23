import pytest
import os
import re
os.environ["PROJ_NETWORK"] = "OFF"
import geopandas as gpd
from shapely.geometry import Point
import networkx as nx
from scripts.diagnose_route import compute_priority

@pytest.mark.skipif(
    not os.path.exists("nl_roads.gpkg") or not os.path.exists("nl_roads_brom.gpkg"),
    reason="GPKG databases are required for integration routing tests."
)
def test_nijkerk_almere_routing():
    # Coords
    start_lat, start_lon = 52.2300, 5.4950
    end_lat, end_lon = 52.3680, 5.3090
    
    # 1. Load data within bbox to optimize speed and avoid full table load
    min_lon, max_lon = min(start_lon, end_lon) - 0.05, max(start_lon, end_lon) + 0.05
    min_lat, max_lat = min(start_lat, end_lat) - 0.05, max(start_lat, end_lat) + 0.05
    bbox = (min_lon, min_lat, max_lon, max_lat)
    
    gdf_raw = gpd.read_file("nl_roads.gpkg", bbox=bbox)
    gdf_brom = gpd.read_file("nl_roads_brom.gpkg")
    blocked_ids = set(gdf_brom['osm_id'].astype(str))
    
    gdf_area = gdf_raw.copy()
    
    # 3. Build Graph
    G = nx.DiGraph()
    
    def get_node_key(pt):
        return (round(pt.y, 5), round(pt.x, 5))
        
    for row in gdf_area.itertuples():
        osm_id = str(row.osm_id)
        geom = row.geometry
        if geom is None or geom.is_empty:
            continue
            
        highway = str(getattr(row, 'highway', '') or '')
        other_tags = str(getattr(row, 'other_tags', '') or '')
        
        # Apply routing profile restrictions
        if osm_id in blocked_ids:
            continue
        if highway in ['motorway', 'motorway_link', 'trunk', 'trunk_link']:
            continue
        if '"motorroad"=>"yes"' in other_tags:
            continue
        
        # Allow microcar=yes overrides by bypassing general prohibitions
        if '"microcar"=>"yes"' not in other_tags:
            if '"motor_vehicle"=>"no"' in other_tags or '"motorcar"=>"no"' in other_tags or '"access"=>"no"' in other_tags:
                continue
            if highway in ['cycleway', 'footway', 'path', 'pedestrian', 'bridleway', 'steps']:
                continue
            
        geom_rd = gpd.GeoSeries([geom], crs="EPSG:4326").to_crs(epsg=28992).iloc[0]
        length_m = geom_rd.length
        
        is_oneway = '"oneway"=>"yes"' in other_tags or '"junction"=>"roundabout"' in other_tags
        is_oneway_rev = '"oneway"=>"-1"' in other_tags
        
        coords = list(geom.coords)
        part_len = length_m / (len(coords) - 1)
        for i in range(len(coords) - 1):
            n1 = get_node_key(Point(coords[i]))
            n2 = get_node_key(Point(coords[i+1]))
            
            if is_oneway_rev:
                G.add_edge(n2, n1, weight=part_len, osm_id=osm_id, name=getattr(row, 'name', None), highway=highway)
            elif is_oneway:
                G.add_edge(n1, n2, weight=part_len, osm_id=osm_id, name=getattr(row, 'name', None), highway=highway)
            else:
                G.add_edge(n1, n2, weight=part_len, osm_id=osm_id, name=getattr(row, 'name', None), highway=highway)
                G.add_edge(n2, n1, weight=part_len, osm_id=osm_id, name=getattr(row, 'name', None), highway=highway)
            
    # 4. Snap start/end to graph
    start_pt = (start_lat, start_lon)
    end_pt = (end_lat, end_lon)
    
    start_node = min(G.nodes, key=lambda n: (n[0]-start_pt[0])**2 + (n[1]-start_pt[1])**2)
    end_node = min(G.nodes, key=lambda n: (n[0]-end_pt[0])**2 + (n[1]-end_pt[1])**2)
    
    # 5. Dijkstra
    path = nx.shortest_path(G, source=start_node, target=end_node, weight='weight')
    
    total_weight = 0
    used_ways = []
    used_names = []
    
    for i in range(len(path) - 1):
        edge_data = G[path[i]][path[i+1]]
        total_weight += edge_data['weight']
        used_ways.append(edge_data['osm_id'])
        if edge_data['name']:
            used_names.append(edge_data['name'].lower())
            
    # Assertions
    # A. Path should be successfully found
    assert len(path) > 0
    # B. Path should be short (under 35km, implying Nijkerkerbrug was used instead of detouring via Harderwijk)
    assert total_weight < 35000.0, f"Route took detour! Distance: {total_weight/1000.0:.2f} km"
    
    # C. Should NOT contain restricted Zeedijk road segments
    zeedijk_count = sum(1 for name in used_names if "zeedijk" in name)
    assert zeedijk_count == 0, f"Route went on Zeedijk {zeedijk_count} times!"

@pytest.mark.skipif(
    not os.path.exists("nl_roads.gpkg") or not os.path.exists("nl_roads_brom.gpkg"),
    reason="GPKG databases are required for integration routing tests."
)
def test_aquamarijnweg_routing():
    # Coords from Dordrecht (North) to Mookhoek (South)
    start_lat, start_lon = 51.80, 4.65
    end_lat, end_lon = 51.7546, 4.6046
    
    # 1. Load data with bbox to optimize
    min_lon, max_lon = min(start_lon, end_lon) - 0.05, max(start_lon, end_lon) + 0.05
    min_lat, max_lat = min(start_lat, end_lat) - 0.05, max(start_lat, end_lat) + 0.05
    bbox = (min_lon, min_lat, max_lon, max_lat)
    
    gdf_raw = gpd.read_file("nl_roads.gpkg", bbox=bbox)
    gdf_brom = gpd.read_file("nl_roads_brom.gpkg")
    blocked_ids = set(gdf_brom['osm_id'].astype(str))
    
    # 2. Build Directed Graph
    G = nx.DiGraph()
    
    def get_node_key(pt):
        return (round(pt.y, 5), round(pt.x, 5))
        
    for row in gdf_raw.itertuples():
        osm_id = str(row.osm_id)
        geom = row.geometry
        if geom is None or geom.is_empty:
            continue
            
        highway = str(getattr(row, 'highway', '') or '')
        other_tags = str(getattr(row, 'other_tags', '') or '')
        
        if osm_id in blocked_ids:
            continue
        if highway in ['motorway', 'motorway_link', 'trunk', 'trunk_link']:
            continue
        if '"motorroad"=>"yes"' in other_tags:
            continue
            
        # Allow microcar=yes overrides by bypassing general prohibitions
        if '"microcar"=>"yes"' not in other_tags:
            if '"motor_vehicle"=>"no"' in other_tags or '"motorcar"=>"no"' in other_tags or '"access"=>"no"' in other_tags:
                continue
            if highway in ['cycleway', 'footway', 'path', 'pedestrian', 'bridleway', 'steps']:
                continue
            
        geom_rd = gpd.GeoSeries([geom], crs="EPSG:4326").to_crs(epsg=28992).iloc[0]
        length_m = geom_rd.length
        
        is_oneway = '"oneway"=>"yes"' in other_tags or '"junction"=>"roundabout"' in other_tags
        is_oneway_rev = '"oneway"=>"-1"' in other_tags
        
        coords = list(geom.coords)
        part_len = length_m / (len(coords) - 1)
        for i in range(len(coords) - 1):
            n1 = get_node_key(Point(coords[i]))
            n2 = get_node_key(Point(coords[i+1]))
            
            if is_oneway_rev:
                G.add_edge(n2, n1, weight=part_len, osm_id=osm_id, name=row.name, highway=highway)
            elif is_oneway:
                G.add_edge(n1, n2, weight=part_len, osm_id=osm_id, name=row.name, highway=highway)
            else:
                G.add_edge(n1, n2, weight=part_len, osm_id=osm_id, name=row.name, highway=highway)
                G.add_edge(n2, n1, weight=part_len, osm_id=osm_id, name=row.name, highway=highway)
                
    start_pt = (start_lat, start_lon)
    end_pt = (end_lat, end_lon)
    
    start_node = min(G.nodes, key=lambda n: (n[0]-start_pt[0])**2 + (n[1]-start_lon)**2)
    end_node = min(G.nodes, key=lambda n: (n[0]-end_pt[0])**2 + (n[1]-end_pt[1])**2)
    
    try:
        path = nx.shortest_path(G, source=start_node, target=end_node, weight='weight')
        used_names = []
        for i in range(len(path) - 1):
            edge_data = G[path[i]][path[i+1]]
            if edge_data['name']:
                used_names.append(edge_data['name'].lower())
        
        # Verify that if a path was found, it avoids Aquamarijnweg entirely
        assert "aquamarijnweg" not in used_names, f"Route used Aquamarijnweg segments: {used_names}"
    except nx.NetworkXNoPath:
        # Since Kiltunnelweg entry points from Dordrecht (trunk Rondweg/Rijksstraatweg and tertiary Aquamarijnweg)
        # are blocked, no directed route for microcars is legally possible.
        pass


@pytest.mark.skipif(
    not os.path.exists("nl_roads.gpkg") or not os.path.exists("nl_roads_brom.gpkg"),
    reason="GPKG databases are required for integration routing tests."
)
def test_strategy3_balanced_default_and_scenic_routing():
    # Coords Avenhorn -> Purmerend (Linda's polder corridor)
    start_lat, start_lon = 52.607, 4.957
    end_lat, end_lon = 52.505, 4.959

    min_lon, max_lon = min(start_lon, end_lon) - 0.05, max(start_lon, end_lon) + 0.05
    min_lat, max_lat = min(start_lat, end_lat) - 0.05, max(start_lat, end_lat) + 0.05
    bbox = (min_lon, min_lat, max_lon, max_lat)

    gdf_raw = gpd.read_file("nl_roads.gpkg", bbox=bbox)
    gdf_brom = gpd.read_file("nl_roads_brom.gpkg")
    blocked_ids = set(gdf_brom['osm_id'].astype(str))

    gdf_area = gdf_raw.copy()

    def build_graph_and_route(avoid_busy_roads=False):
        G = nx.DiGraph()

        def get_node_key(pt):
            return (round(pt.y, 5), round(pt.x, 5))

        for row in gdf_area.itertuples():
            osm_id = str(row.osm_id)
            geom = row.geometry
            if geom is None or geom.is_empty:
                continue

            highway = str(getattr(row, 'highway', '') or '')
            other_tags = str(getattr(row, 'other_tags', '') or '')

            if osm_id in blocked_ids or '"microcar"=>"no"' in other_tags:
                continue
            if highway in ['motorway', 'trunk'] or '"motorroad"=>"yes"' in other_tags:
                continue

            if '"microcar"=>"yes"' not in other_tags:
                if '"motor_vehicle"=>"no"' in other_tags or '"motorcar"=>"no"' in other_tags or '"access"=>"no"' in other_tags:
                    continue
                if highway in ['cycleway', 'footway', 'path', 'pedestrian', 'bridleway', 'steps']:
                    continue

            geom_rd = gpd.GeoSeries([geom], crs="EPSG:4326").to_crs(epsg=28992).iloc[0]
            length_m = geom_rd.length

            speed_kmh = 45.0
            if highway in ['residential', 'service']:
                speed_kmh = 30.0
            elif highway == 'living_street':
                speed_kmh = 15.0

            raw_maxspeed = None
            maxspeed_match = re.search(r'"maxspeed(?:|:motorcar)"=>"(\d+)"', other_tags)
            if maxspeed_match:
                try:
                    raw_maxspeed = int(maxspeed_match.group(1))
                    speed_kmh = max(5.0, min(float(raw_maxspeed), 45.0))
                except ValueError:
                    pass

            speed_mps = speed_kmh / 3.6
            priority = compute_priority(highway, raw_maxspeed, other_tags, avoid_busy_roads=avoid_busy_roads)

            travel_time_sec = (length_m / speed_mps) / priority

            is_oneway = '"oneway"=>"yes"' in other_tags or '"junction"=>"roundabout"' in other_tags
            is_oneway_rev = '"oneway"=>"-1"' in other_tags

            coords = list(geom.coords)
            part_time = travel_time_sec / (len(coords) - 1)
            for i in range(len(coords) - 1):
                n1 = get_node_key(Point(coords[i]))
                n2 = get_node_key(Point(coords[i+1]))

                if is_oneway_rev:
                    G.add_edge(n2, n1, weight=part_time, osm_id=osm_id, name=row.name, highway=highway)
                elif is_oneway:
                    G.add_edge(n1, n2, weight=part_time, osm_id=osm_id, name=row.name, highway=highway)
                else:
                    G.add_edge(n1, n2, weight=part_time, osm_id=osm_id, name=row.name, highway=highway)
                    G.add_edge(n2, n1, weight=part_time, osm_id=osm_id, name=row.name, highway=highway)

        start_pt = (start_lat, start_lon)
        end_pt = (end_lat, end_lon)
        start_node = min(G.nodes, key=lambda n: (n[0]-start_pt[0])**2 + (n[1]-start_pt[1])**2)
        end_node = min(G.nodes, key=lambda n: (n[0]-end_pt[0])**2 + (n[1]-end_pt[1])**2)

        path = nx.shortest_path(G, source=start_node, target=end_node, weight='weight')
        names = []
        for i in range(len(path) - 1):
            e = G[path[i]][path[i+1]]
            if e['name']:
                names.append(e['name'].lower())
        return names

    # Under Strategy 3 balanced default (priority=0.55 on 80kmh), 80km/h Middenweg is avoided automatically
    names_default = build_graph_and_route(avoid_busy_roads=False)
    assert not any("middenweg" in n for n in names_default), f"Expected no Middenweg in balanced default: {names_default}"
    assert any("zomerdijk" in n or "beets" in n for n in names_default), f"Expected polder bypass route: {names_default}"

    # Under avoid_busy_roads=True, quiet dyke route is also chosen
    names_avoid_busy = build_graph_and_route(avoid_busy_roads=True)
    assert not any("middenweg" in n for n in names_avoid_busy), f"Expected no Middenweg when avoiding busy roads: {names_avoid_busy}"
    assert any("zomerdijk" in n or "beets" in n for n in names_avoid_busy), f"Expected polder bypass route: {names_avoid_busy}"


def test_routing_xml_priority_and_access_invariants():
    import xml.etree.ElementTree as ET

    root = ET.parse("config/routing.xml").getroot()
    profile = root.find("routingProfile[@name='BromBrom']")
    assert profile is not None

    # Pruned noisy/non-microcar toggles stay absent; relevant toggles stay present
    param_ids = {p.attrib.get("id") for p in profile.findall("parameter")}
    for removed in ("prefer_unpaved", "avoid_shuttle_train", "avoid_ice_roads_fords", "goods_restrictions", "avoid_4wd_only"):
        assert removed not in param_ids, f"Unexpected parameter: {removed}"
    for kept in ("avoid_busy_roads", "avoid_tunnels", "avoid_borders", "avoid_ferries", "avoid_unpaved", "avoid_toll", "avoid_low_emission_zone"):
        assert kept in param_ids, f"Missing expected parameter: {kept}"

    # Access invariants: hard prohibitions (incl. fords/ice/4wd) must precede microcar=yes
    access_rules = [
        (elem.attrib.get("t"), elem.attrib.get("v"), elem.attrib.get("value"))
        for elem in profile.find("way[@attribute='access']")
        if elem.tag == "select"
    ]
    idx_microcar_yes = access_rules.index(("microcar", "yes", "1"))
    for tag in [
        ("microcar", "no", "-1"),
        ("osmand_change", "delete", "-1"),
        ("highway", "construction", "-1"),
        ("ford", "yes", "-1"),
        ("ice_road", "yes", "-1"),
        ("4wd_only", "yes", "-1"),
    ]:
        assert access_rules.index(tag) < idx_microcar_yes, f"{tag} must precede microcar=yes"

    # Penalty transition invariants: avoid_tunnels & gravel must precede highway classes
    pen_flat = []
    for elem in profile.find("way[@attribute='penalty_transition']"):
        if elem.tag == "select":
            pen_flat.append((None, elem.attrib.get("t"), elem.attrib.get("v")))
        elif elem.tag == "if":
            for sub in elem.findall("select"):
                pen_flat.append((elem.attrib.get("param"), sub.attrib.get("t"), sub.attrib.get("v")))
    assert pen_flat.index(("avoid_tunnels", "tunnel", "yes")) < pen_flat.index((None, "highway", "primary"))
    assert pen_flat.index((None, "surface", "gravel")) < pen_flat.index((None, "highway", "primary"))

    # Priority invariants (OsmAnd first-match top-to-bottom)
    prio_flat = []
    for elem in profile.find("way[@attribute='priority']"):
        if elem.tag == "select":
            prio_flat.append((None, elem.attrib.get("t"), elem.attrib.get("v"), float(elem.attrib["value"])))
        elif elem.tag == "if":
            param = elem.attrib.get("param")
            for sub in elem.findall("select"):
                prio_flat.append((param, sub.attrib.get("t"), sub.attrib.get("v"), float(sub.attrib["value"])))

    def find_idx(param, t, v):
        for i, (p, kt, kv, _) in enumerate(prio_flat):
            if p == param and kt == t and kv == v:
                return i
        raise AssertionError(f"Missing rule ({param}, {t}={v})")

    # 1. Balanced default 80 km/h and avoid_busy_roads 80 km/h bounds
    def_80 = prio_flat[find_idx(None, "maxspeed", "80")][3]
    ab_80 = prio_flat[find_idx("avoid_busy_roads", "maxspeed", "80")][3]
    assert 0.5 <= def_80 <= 0.65, f"Default maxspeed=80 priority out of range: {def_80}"
    assert 0.05 <= ab_80 <= 0.2, f"avoid_busy_roads maxspeed=80 priority out of range: {ab_80}"

    # 2. No >1.0 priority (45 km/h clamp causes 30 km/h urban bias)
    for param, t, v, val in prio_flat:
        assert val <= 1.0, f"Priority > 1.0: ({param}, {t}={v}, {val})"

    # 3. Strictest-first ordering checks (prevents shadowing & inversions)
    assert find_idx("avoid_tunnels", "tunnel", "yes") < find_idx(None, "maxspeed", "80")
    assert find_idx("avoid_busy_roads", "maxspeed", "80") < find_idx(None, "smoothness", "horrible")
    assert find_idx(None, "smoothness", "horrible") < find_idx(None, "maxspeed", "60")
    assert find_idx(None, "surface", "unpaved") < find_idx(None, "smoothness", "bad")
    assert find_idx(None, "maxspeed", "80") < find_idx(None, "smoothness", "bad")
    assert find_idx(None, "surface", "unpaved") < find_idx(None, "maxspeed", "60")
    assert find_idx(None, "highway", "living_street") < find_idx(None, "maxspeed", "60")
    assert find_idx(None, "highway", "service") < find_idx(None, "maxspeed", "60")
    assert find_idx("avoid_busy_roads", "highway", "primary") < find_idx("avoid_busy_roads", "maxspeed", "70")
    assert find_idx(None, "surface", "cobblestone") < find_idx("avoid_busy_roads", "maxspeed", "60")
    assert find_idx(None, "surface", "cobblestone") < find_idx(None, "maxspeed", "60")




