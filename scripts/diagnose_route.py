#!/usr/bin/env python3
import argparse
import sys
import os
import json
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
    
    # 1. Load roads
    print("Loading databases...")
    gdf_raw = gpd.read_file("nl_roads.gpkg")
    gdf_brom = gpd.read_file("nl_roads_brom.gpkg")
    
    blocked_ids = set(gdf_brom['osm_id'].astype(str))
    print(f"Loaded {len(gdf_raw)} raw roads and {len(blocked_ids)} blocked roads.")
    
    # 2. Filter to bounding box containing start and end coordinates with padding
    min_lon = min(start_lon, end_lon) - 0.05
    max_lon = max(start_lon, end_lon) + 0.05
    min_lat = min(start_lat, end_lat) - 0.05
    max_lat = max(start_lat, end_lat) + 0.05
    
    print(f"Filtering roads to bounding box: Lon [{min_lon:.4f}, {max_lon:.4f}], Lat [{min_lat:.4f}, {max_lat:.4f}]...")
    # Using centroid to approximate spatial filter
    bbox_mask = (
        (gdf_raw.geometry.centroid.x >= min_lon) & (gdf_raw.geometry.centroid.x <= max_lon) &
        (gdf_raw.geometry.centroid.y >= min_lat) & (gdf_raw.geometry.centroid.y <= max_lat)
    )
    gdf_area = gdf_raw[bbox_mask].copy()
    print(f"Road segments in search area: {len(gdf_area)}")
    
    if len(gdf_area) == 0:
        print("❌ Error: No road segments found in the bounding box.")
        sys.exit(1)
        
    # 3. Build NetworkX Graph
    print("Building NetworkX routing graph...")
    G = nx.Graph()
    
    def get_node_key(pt):
        # Round to 5 decimal places (~1.1 meter precision) to match intersection vertices
        return (round(pt.y, 5), round(pt.x, 5))
        
    for idx, row in gdf_area.iterrows():
        osm_id = str(row['osm_id'])
        geom = row.geometry
        if geom is None or geom.is_empty:
            continue
            
        highway = str(row.get('highway') or '')
        other_tags = str(row.get('other_tags') or '')
        
        # Apply routing.xml BromBrom restrictions
        # A. Blocked by snapped NDW C9 signs
        if osm_id in blocked_ids:
            continue
            
        # B. Blocked by class (motorway, motorway_link, trunk, trunk_link)
        if highway in ['motorway', 'motorway_link', 'trunk', 'trunk_link']:
            continue
            
        # C. Blocked by motorroad=yes tag
        if '"motorroad"=>"yes"' in other_tags:
            continue
            
        # D. Blocked by access/motor_vehicle/motorcar restrictions in OSM
        if '"motor_vehicle"=>"no"' in other_tags or '"motorcar"=>"no"' in other_tags or '"access"=>"no"' in other_tags:
            continue
            
        # Project geometry to RD New (EPSG:28992) for accurate metric length calculation
        geom_rd = gpd.GeoSeries([geom], crs="EPSG:4326").to_crs(epsg=28992).iloc[0]
        length_m = geom_rd.length
        
        coords = list(geom.coords)
        for i in range(len(coords) - 1):
            n1 = get_node_key(Point(coords[i]))
            n2 = get_node_key(Point(coords[i+1]))
            # Edge weight is length in meters
            part_len = length_m / (len(coords) - 1)
            G.add_edge(n1, n2, weight=part_len, osm_id=osm_id, name=row.get('name'), highway=highway)
            
    print(f"Graph built with {G.number_of_nodes()} nodes and {G.number_of_edges()} edges.")
    
    if G.number_of_nodes() == 0:
        print("❌ Error: Graph has no nodes.")
        sys.exit(1)
        
    # 4. Find nearest nodes to start/end coords
    start_pt = (start_lat, start_lon)
    end_pt = (end_lat, end_lon)
    
    start_node = min(G.nodes, key=lambda n: (n[0]-start_pt[0])**2 + (n[1]-start_lon)**2) # Wait, corrected distance formula
    # Let's use simple euclidean distance check
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
        total_weight = 0
        current_way = None
        current_name = None
        current_highway = None
        current_weight = 0
        
        for i in range(len(path) - 1):
            edge_data = G[path[i]][path[i+1]]
            weight = edge_data['weight']
            osm_id = edge_data['osm_id']
            name = edge_data['name']
            highway = edge_data['highway']
            total_weight += weight
            
            if osm_id != current_way:
                if current_way is not None:
                    print(f"  OSM Way: {current_way:<12} | Name: {str(current_name):<25} | Highway: {current_highway:<15} | Length: {current_weight:.1f}m")
                current_way = osm_id
                current_name = name
                current_highway = highway
                current_weight = weight
            else:
                current_weight += weight
                
        if current_way is not None:
            print(f"  OSM Way: {current_way:<12} | Name: {str(current_name):<25} | Highway: {current_highway:<15} | Length: {current_weight:.1f}m")
            
        print(f"\nTotal Route Distance: {total_weight/1000.0:.3f} km")
        return total_weight, path
        
    except nx.NetworkXNoPath:
        print("❌ Error: No route exists between the start and end nodes!")
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
