import pytest
import os
import geopandas as gpd
from shapely.geometry import Point
import networkx as nx

@pytest.mark.skipif(
    not os.path.exists("nl_roads.gpkg") or not os.path.exists("nl_roads_brom.gpkg"),
    reason="GPKG databases are required for integration routing tests."
)
def test_nijkerk_almere_routing():
    # Coords
    start_lat, start_lon = 52.2300, 5.4950
    end_lat, end_lon = 52.3680, 5.3090
    
    # 1. Load data
    gdf_raw = gpd.read_file("nl_roads.gpkg")
    gdf_brom = gpd.read_file("nl_roads_brom.gpkg")
    blocked_ids = set(gdf_brom['osm_id'].astype(str))
    
    # 2. Filter to search area with margin
    min_lon, max_lon = min(start_lon, end_lon) - 0.05, max(start_lon, end_lon) + 0.05
    min_lat, max_lat = min(start_lat, end_lat) - 0.05, max(start_lat, end_lat) + 0.05
    
    bbox_mask = (
        (gdf_raw.geometry.centroid.x >= min_lon) & (gdf_raw.geometry.centroid.x <= max_lon) &
        (gdf_raw.geometry.centroid.y >= min_lat) & (gdf_raw.geometry.centroid.y <= max_lat)
    )
    gdf_area = gdf_raw[bbox_mask].copy()
    
    # 3. Build Graph
    G = nx.Graph()
    
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
        if '"motor_vehicle"=>"no"' in other_tags or '"motorcar"=>"no"' in other_tags or '"access"=>"no"' in other_tags:
            continue
            
        geom_rd = gpd.GeoSeries([geom], crs="EPSG:4326").to_crs(epsg=28992).iloc[0]
        length_m = geom_rd.length
        
        coords = list(geom.coords)
        for i in range(len(coords) - 1):
            n1 = get_node_key(Point(coords[i]))
            n2 = get_node_key(Point(coords[i+1]))
            part_len = length_m / (len(coords) - 1)
            G.add_edge(n1, n2, weight=part_len, osm_id=osm_id, name=getattr(row, 'name', None), highway=highway)
            
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
    
    # C. Should NOT contain restricted Zeedijk road segments (except for minor crossings/parking if any,
    # but the main road routing should not have name "zeedijk")
    zeedijk_count = sum(1 for name in used_names if "zeedijk" in name)
    # The route should avoid Zeedijk
    assert zeedijk_count == 0, f"Route went on Zeedijk {zeedijk_count} times!"
