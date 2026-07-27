#!/usr/bin/env python3
import argparse
import sys
import os
os.environ["PROJ_NETWORK"] = "OFF"
import re
import json
import sqlite3
import geopandas as gpd
import pandas as pd
import networkx as nx
from shapely.geometry import Point, box

# Ensure the root of the project is in path
sys.path.append(os.getcwd())

def check_files():
    required = ["nl_roads.gpkg", "nl_roads_brom.gpkg"]
    missing = [f for f in required if not os.path.exists(f)]
    if missing:
        print(f"❌ Error: Missing required files: {', '.join(missing)}")
        print("Please build or fetch the databases first.")
        sys.exit(1)

def simulate_route(start_lat, start_lon, end_lat, end_lon):
    print(f"\n================ SIMULATING ROUTE ================")
    print(f"Start: ({start_lat}, {start_lon})")
    print(f"End:   ({end_lat}, {end_lon})")
    
    # 1. Calculate adaptive bounding box containing start and end coordinates
    dist_deg = ((start_lat - end_lat)**2 + (start_lon - end_lon)**2)**0.5
    padding = max(0.015, min(0.05, dist_deg * 0.6))
    
    min_lon = min(start_lon, end_lon) - padding
    max_lon = max(start_lon, end_lon) + padding
    min_lat = min(start_lat, end_lat) - padding
    max_lat = max(start_lat, end_lat) + padding
    
    print(f"Filtering roads to bounding box: Lon [{min_lon:.4f}, {max_lon:.4f}], Lat [{min_lat:.4f}, {max_lat:.4f}] (padding: {padding:.4f})...")
    bbox = (min_lon, min_lat, max_lon, max_lat)
    
    # 2. Load databases (optimizing raw roads load with bbox to avoid reading 527MB table)
    print("Loading databases...")
    gdf_raw = gpd.read_file("nl_roads.gpkg", bbox=bbox)
    with sqlite3.connect("nl_roads_brom.gpkg") as conn:
        tbl = conn.execute("SELECT table_name FROM gpkg_contents WHERE data_type='features'").fetchone()[0]
        blocked_ids = {str(r[0]) for r in conn.execute(f"SELECT osm_id FROM {tbl}")}
    print(f"Loaded {len(gdf_raw)} raw roads in search area and {len(blocked_ids)} blocked roads.")
    gdf_area = gdf_raw.copy()
    if len(gdf_area) == 0:
        print("❌ Error: No road segments found in the bounding box.")
        sys.exit(1)
    gdf_area['length_m'] = gdf_area.to_crs(epsg=28992).length
    print(f"Road segments in search area: {len(gdf_area)}")
        
    # 3. Build NetworkX Routing Graph with OsmAnd Node/Turn Penalties
    print("Building NetworkX routing graph (including OsmAnd traffic signal & turn penalties)...")
    G = nx.DiGraph()
    signal_nodes = set()
    
    def get_node_key(pt):
        # Round to 5 decimal places (~1.1 meter precision) to match intersection vertices
        return (round(pt.y, 5), round(pt.x, 5))
        
    for row in gdf_area.itertuples():
        osm_id = str(row.osm_id)
        geom = row.geometry
        if geom is None or geom.is_empty:
            continue
            
        highway = str(getattr(row, 'highway', '') or '')
        other_tags = str(getattr(row, 'other_tags', '') or '')
        
        # Track traffic signal indicators
        has_signal = '"highway"=>"traffic_signals"' in other_tags or '"traffic_signals"' in other_tags
        
        # Apply routing.xml BromBrom restrictions
        # A. Blocked by snapped NDW C9 signs or explicit microcar=no
        if osm_id in blocked_ids or '"microcar"=>"no"' in other_tags:
            continue
            
        # B. Blocked by main highway class (motorway, trunk, motorroad=yes)
        if highway in ['motorway', 'trunk'] or '"motorroad"=>"yes"' in other_tags:
            continue
            
        is_link_ramp = highway in ['motorway_link', 'trunk_link']
            
        # C. Allow microcar=yes overrides by bypassing general access/motor_vehicle/cycleway blocks
        if '"microcar"=>"yes"' not in other_tags:
            if '"motor_vehicle"=>"no"' in other_tags or '"motorcar"=>"no"' in other_tags or '"access"=>"no"' in other_tags:
                continue
            if highway in ['cycleway', 'footway', 'path', 'pedestrian', 'bridleway', 'steps']:
                continue
            
        # Project geometry to RD New (EPSG:28992) for accurate metric length calculation
        is_oneway = '"oneway"=>"yes"' in other_tags or '"junction"=>"roundabout"' in other_tags
        is_oneway_rev = '"oneway"=>"-1"' in other_tags
        coords = list(geom.coords)
        if len(coords) < 2:
            continue
        length_m = row.length_m

        # Calculate OsmAnd travel time & priority weighting (matching routing.xml)
        speed_kmh = 45.0
        if highway == 'residential' or highway == 'service':
            speed_kmh = 30.0
        elif highway == 'living_street':
            speed_kmh = 15.0

        # Parse maxspeed if present
        maxspeed_match = re.search(r'"maxspeed"=>"(\d+)"', other_tags)
        if maxspeed_match:
            try:
                speed_kmh = max(5.0, min(float(maxspeed_match.group(1)), 45.0))
            except ValueError:
                pass

        speed_mps = speed_kmh / 3.6
        priority = 1.0

        # Destination traffic penalty (routing.xml priority=0.15)
        if '"motor_vehicle"=>"destination"' in other_tags or '"access"=>"destination"' in other_tags or '"motorcar"=>"destination"' in other_tags:
            priority *= 0.15

        # Surface penalties (routing.xml)
        if '"surface"=>"unpaved"' in other_tags or '"surface"=>"gravel"' in other_tags:
            priority *= 0.5

        # Compute travel time in seconds adjusted for priority
        travel_time_sec = (length_m / speed_mps) / priority
        if is_link_ramp:
            travel_time_sec += 36000.0  # matching routing.xml penalty_transition=36000 for link ramps
        part_len = length_m / (len(coords) - 1)
        part_time = travel_time_sec / (len(coords) - 1)

        for i in range(len(coords) - 1):
            n1 = get_node_key(Point(coords[i]))
            n2 = get_node_key(Point(coords[i+1]))
            
            if has_signal:
                signal_nodes.add(n1)
                signal_nodes.add(n2)
            
            edge_attrs = {
                'weight': part_time, # Default to OsmAnd travel time for shortest_path
                'length': part_len,
                'time_sec': part_time,
                'osm_id': osm_id,
                'name': getattr(row, 'name', None),
                'highway': highway
            }
            
            if is_oneway_rev:
                G.add_edge(n2, n1, **edge_attrs)
            elif is_oneway:
                G.add_edge(n1, n2, **edge_attrs)
            else:
                G.add_edge(n1, n2, **edge_attrs)
                G.add_edge(n2, n1, **edge_attrs)

    # Apply OsmAnd traffic signal node penalties (routing.xml: 15s penalty)
    for snode in signal_nodes:
        if snode in G:
            for nbr in G.successors(snode):
                G[snode][nbr]['weight'] += 15.0
                G[snode][nbr]['time_sec'] += 15.0

            
    print(f"Graph built with {G.number_of_nodes()} nodes and {G.number_of_edges()} edges (OsmAnd Time & Priority weighted).")
    
    if G.number_of_nodes() == 0:
        print("❌ Error: Graph has no nodes.")
        sys.exit(1)
        
    # 4. Find nearest nodes to start/end coords
    start_pt = (start_lat, start_lon)
    end_pt = (end_lat, end_lon)
    
    start_node = min(G.nodes, key=lambda n: (n[0]-start_pt[0])**2 + (n[1]-start_pt[1])**2)
    end_node = min(G.nodes, key=lambda n: (n[0]-end_pt[0])**2 + (n[1]-end_pt[1])**2)
    
    # Distance in meters (rough conversion)
    start_dist = ((start_node[0]-start_pt[0])**2 + (start_node[1]-start_pt[1])**2)**0.5 * 111000
    end_dist = ((end_node[0]-end_pt[0])**2 + (end_node[1]-end_pt[1])**2)**0.5 * 111000
    
    print(f"Snapped Start to node: {start_node} (distance {start_dist:.1f}m)")
    print(f"Snapped End to node:   {end_node} (distance {end_dist:.1f}m)")
    
    # 5. Dijkstra Routing
    try:
        path = nx.shortest_path(G, source=start_node, target=end_node, weight='weight')
        print(f"\n✅ Shortest path found: {len(path)} nodes.")
        
        print("\n--- Route Directions ---")
        total_length_m = 0
        total_time_sec = 0
        current_way = None
        current_name = None
        current_highway = None
        current_way_len = 0
        
        for i in range(len(path) - 1):
            edge_data = G[path[i]][path[i+1]]
            length = edge_data['length']
            t_sec = edge_data['time_sec']
            osm_id = edge_data['osm_id']
            name = edge_data['name']
            highway = edge_data['highway']
            total_length_m += length
            total_time_sec += t_sec
            
            if osm_id != current_way:
                if current_way is not None:
                    print(f"  OSM Way: {current_way:<12} | Name: {str(current_name):<25} | Highway: {current_highway:<15} | Length: {current_way_len:.1f}m")
                current_way = osm_id
                current_name = name
                current_highway = highway
                current_way_len = length
            else:
                current_way_len += length
                
        if current_way is not None:
            print(f"  OSM Way: {current_way:<12} | Name: {str(current_name):<25} | Highway: {current_highway:<15} | Length: {current_way_len:.1f}m")
            
        print(f"\nTotal Route Distance : {total_length_m/1000.0:.3f} km")
        print(f"OsmAnd Est. Time     : {total_time_sec/60.0:.1f} min")
        return total_length_m, path
        
    except nx.NetworkXNoPath:
        print("\n❌ Error: No route exists between the start and end nodes!")
        print("\n================ ROUTE DIAGNOSTIC REPORT ================")
        
        # Stage 1: Check if an undirected path exists (One-Way Bottleneck Check)
        G_undir = G.to_undirected()
        if nx.has_path(G_undir, start_node, end_node):
            undir_path = nx.shortest_path(G_undir, source=start_node, target=end_node, weight='weight')
            print(f"ℹ️ An undirected route exists ({len(undir_path)} nodes). Checking one-way directional bottlenecks...\n")
            
            broken_one_ways = []
            for i in range(len(undir_path) - 1):
                u, v = undir_path[i], undir_path[i+1]
                if not G.has_edge(u, v):
                    rev_info = G.get_edge_data(v, u)
                    if rev_info:
                        broken_one_ways.append((u, v, rev_info))
                        
            if broken_one_ways:
                print(f"🚨 FOUND {len(broken_one_ways)} ONE-WAY BOTTLENECK(S) BLOCKING THIS DIRECTION:\n")
                for idx, (u, v, info) in enumerate(broken_one_ways, 1):
                    wid = info.get('osm_id')
                    hway = info.get('highway')
                    wname = info.get('name') or '(unnamed)'
                    url = f"https://www.openstreetmap.org/way/{wid}"
                    print(f"  {idx}. OSM Way {wid} ({hway}) name='{wname}'")
                    print(f"     Reason: Tagged 'oneway=yes' pointing in the REVERSE direction ({v} -> {u}).")
                    print(f"     URL:    {url}\n")
                print("💡 Recommendation: Inspect the listed way(s) on OpenStreetMap. If the segment is physically bi-directional, update 'oneway=no' in OSM.")
                return None, None
        
        # Stage 2: Spatial Disconnection & Gap Analysis
        print("ℹ️ The road network graph is physically disconnected between Start and End.\n")
        start_comp = list(nx.descendants(G, start_node) | {start_node})
        end_comp = list(nx.ancestors(G, end_node) | {end_node})
        
        print(f"  Start Component: {len(start_comp):,} reachable nodes")
        print(f"  End Component:   {len(end_comp):,} reachable nodes\n")
        
        # Fast O(N log M) spatial lookup using scipy cKDTree (scaled for latitude)
        import math
        from scipy.spatial import cKDTree
        mid_lat_rad = math.radians((start_node[0] + end_node[0]) / 2.0)
        cos_lat = math.cos(mid_lat_rad)
        
        start_scaled = [(n[0], n[1] * cos_lat) for n in start_comp]
        end_scaled = [(n[0], n[1] * cos_lat) for n in end_comp]
        
        tree = cKDTree(end_scaled)
        distances, indices = tree.query(start_scaled)
        min_idx = distances.argmin()
        best_pair = (start_comp[min_idx], end_comp[indices[min_idx]])
        min_sq = distances[min_idx] ** 2
                    
        if best_pair:
            gap_m = (min_sq ** 0.5) * 111000
            mid_lat = (best_pair[0][0] + best_pair[1][0]) / 2.0
            mid_lon = (best_pair[0][1] + best_pair[1][1]) / 2.0
            print(f"📍 Closest Graph Gap: {gap_m:.1f} meters apart near ({mid_lat:.5f}, {mid_lon:.5f})")
            
            # Inspect candidate roads near the gap in raw data
            gap_box = box(min(best_pair[0][1], best_pair[1][1]) - 0.002, min(best_pair[0][0], best_pair[1][0]) - 0.002,
                          max(best_pair[0][1], best_pair[1][1]) + 0.002, max(best_pair[0][0], best_pair[1][0]) + 0.002)
            gap_roads = gdf_raw[gdf_raw.geometry.intersects(gap_box)]
            
            if not gap_roads.empty:
                print(f"\nCandidate road segments near the gap ({len(gap_roads)}):")
                for idx, r in gap_roads.iterrows():
                    wid = str(r['osm_id'])
                    hway = r['highway']
                    wname = r['name'] or '(unnamed)'
                    tags = str(r['other_tags'] or '')
                    is_c9_blocked = wid in blocked_ids
                    
                    reasons = []
                    if is_c9_blocked:
                        reasons.append("C9_TRAFFIC_SIGN_BLOCKED")
                    if hway in ['motorway', 'motorway_link', 'trunk', 'trunk_link']:
                        reasons.append(f"CLASS_BLOCKED({hway})")
                    if '"motorroad"=>"yes"' in tags:
                        reasons.append("MOTORROAD_YES")
                    if '"microcar"=>"yes"' not in tags:
                        if '"motor_vehicle"=>"no"' in tags or '"motorcar"=>"no"' in tags or '"access"=>"no"' in tags:
                            reasons.append("MOTOR_VEHICLE_NO")
                        if hway in ['cycleway', 'footway', 'path', 'pedestrian', 'bridleway', 'steps']:
                            reasons.append(f"CYCLEWAY_WITHOUT_MICROCAR_YES({hway})")
                            
                    reason_str = ", ".join(reasons) if reasons else "UNKNOWN_DISCONNECTION"
                    print(f"  • OSM Way {wid} ({hway}) name='{wname}' | Status: {reason_str}")
                    print(f"    URL: https://www.openstreetmap.org/way/{wid}")
                    
        print("=========================================================\n")
        return None, None

def main():
    parser = argparse.ArgumentParser(description="BromBrom Map Routing Simulator & Diagnostics CLI")
    parser.add_argument("--start", required=True, help="Start coordinates as 'lat,lon' (e.g. '52.2300,5.4950')")
    parser.add_argument("--end", required=True, help="End coordinates as 'lat,lon' (e.g. '52.3680,5.3090')")
    
    args = parser.parse_args()
    
    check_files()
    
    try:
        start_lat, start_lon = map(float, args.start.split(','))
        end_lat, end_lon = map(float, args.end.split(','))
    except Exception as e:
        print(f"❌ Error parsing coordinates. Must be 'lat,lon'. Details: {e}")
        sys.exit(1)
        
    simulate_route(start_lat, start_lon, end_lat, end_lon)

if __name__ == "__main__":
    main()
