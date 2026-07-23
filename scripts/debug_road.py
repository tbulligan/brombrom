#!/usr/bin/env python3
"""
BromBrom Diagnostic CLI Tool
============================
A high-performance command-line debugging tool to inspect the tagging pipeline status of specific roads,
signs, or search the network on-demand.

Usage:
  python scripts/debug_road.py --way <OSM_ID> [--pull]
  python scripts/debug_road.py --sign <SIGN_ID> [--pull]
  python scripts/debug_road.py --name <ROAD_NAME> [--level0] [--min-speed 80] [--pull]
  python scripts/debug_road.py --coords <LAT,LON> [--pull]
"""
import argparse
import os
os.environ["PROJ_NETWORK"] = "OFF"
import sys
import json
import sqlite3
import subprocess
import struct

def make_streetview_url(lat, lon):
    if lat is None or lon is None:
        return ""
    return f"https://www.google.com/maps?q=&layer=c&cbll={lat:.6f},{lon:.6f}"

def make_osm_url(way_id):
    return f"https://www.openstreetmap.org/way/{way_id}"

def get_lat_lon_from_gpb(blob):
    """Extract (lat, lon) in WGS84 from any GeoPackage GPB geometry BLOB."""
    if not blob or len(blob) < 8:
        return None, None
    flags = blob[3]
    env_ind = (flags >> 1) & 0x07
    env_sizes = {0: 0, 1: 32, 2: 48, 3: 48, 4: 64}
    offset = 8 + env_sizes.get(env_ind, 0)
    if len(blob) < offset + 21:
        return None, None
    byte_order = blob[offset]
    fmt = '<' if byte_order == 1 else '>'
    gtype = struct.unpack(fmt + 'I', blob[offset+1:offset+5])[0]
    if gtype in (1, 1001): # Point or PointZ
        x, y = struct.unpack(fmt + 'dd', blob[offset+5:offset+21])
        # If coordinates are already WGS84 (x=lon in 3..7, y=lat in 50..54)
        if -180 <= x <= 180 and -90 <= y <= 90:
            return y, x
        # Otherwise RD New (x ~ 150000, y ~ 450000)
        return rd_to_wgs84(x, y)
    return None, None

def rd_to_wgs84(x, y):
    """Fast RD New (EPSG:28992) to WGS84 (EPSG:4326) approximation."""
    if x is None or y is None:
        return None, None
    dx = (x - 155000) * 1e-5
    dy = (y - 463000) * 1e-5
    lat = 52.1551744 + (3238.8837 * dy - 32.50 * dx**2 - 0.247 * dy**2 - 0.85 * dx**2 * dy - 0.16 * dy**3) / 3600.0
    lon = 5.38720621 + (5261.3028 * dx + 105.978 * dx * dy + 2.456 * dx * dy**2 - 0.818 * dx**3) / 3600.0
    return lat, lon

def pull_freshest_data():
    print("\n================ REFRESHING PIPELINE DATA ================")
    files_to_delete = [
        "ndw_current_state.json",
        "c9_ndw.gpkg",
        "nl_map.osm.pbf",
        "nl_roads.osm.pbf",
        "nl_roads.gpkg",
        "nl_roads_brom.gpkg",
        "debug_snaps.gpkg",
        "missed_c9.gpkg",
        "c9_exemptions.gpkg"
    ]
    for f in files_to_delete:
        if os.path.exists(f):
            print(f"Removing old file: {f}")
            try:
                os.remove(f)
            except Exception as e:
                print(f"Warning: Could not remove {f}: {e}")
                
    scripts = [
        "scripts/fetch_nl_signs.py",
        "scripts/extract_c9.py",
        "scripts/fetch_nl_map.py",
        "scripts/extract_roads.py",
        "scripts/snap_c9_to_roads.py"
    ]
    for script in scripts:
        print(f"\nRunning {script}...")
        subprocess.run([sys.executable, script], check=True)
    print("\n✓ Pipeline data successfully refreshed!")

def check_files(auto_pull=False):
    required = ["c9_ndw.gpkg", "nl_roads.gpkg", "nl_roads_brom.gpkg"]
    missing = [f for f in required if not os.path.exists(f)]
    if missing:
        if auto_pull:
            print(f"Missing required databases: {', '.join(missing)}")
            print("Triggering automatic data download...")
            pull_freshest_data()
        else:
            print(f"❌ Error: Missing required files: {', '.join(missing)}")
            print("Please run this script with --pull to fetch the required data.")
            sys.exit(1)

def inspect_way(way_id):
    print(f"\n================ INSPECTING WAY: {way_id} ================")
    
    # 1. Direct fast SQLite lookup in raw roads network (nl_roads.gpkg)
    print("\n--- 1. Raw OSM Road Data (nl_roads.gpkg) ---")
    conn_raw = sqlite3.connect("nl_roads.gpkg")
    cur_raw = conn_raw.cursor()
    row_raw = cur_raw.execute("SELECT name, highway, other_tags, geom FROM lines WHERE osm_id = ?", (str(way_id),)).fetchone()
    
    if not row_raw:
        print(f"Way {way_id} not found in raw road database.")
    else:
        name, hw, tags, geom = row_raw
        lat, lon = get_lat_lon_from_gpb(geom)
        print(f"  Name:       {name}")
        print(f"  Highway:    {hw}")
        print(f"  Other Tags: {tags}")
        print(f"  OSM URL:    {make_osm_url(way_id)}")
        if lat and lon:
            print(f"  StreetView: {make_streetview_url(lat, lon)}")
        
    # 2. Direct fast SQLite lookup in processed network (nl_roads_brom.gpkg)
    print("\n--- 2. Processed/Blocked Road Data (nl_roads_brom.gpkg) ---")
    conn_brom = sqlite3.connect("nl_roads_brom.gpkg")
    cur_brom = conn_brom.cursor()
    row_brom = cur_brom.execute("SELECT name, highway, microcar, c9_snaps FROM brom_roads WHERE osm_id = ?", (str(way_id),)).fetchone()
    
    if not row_brom:
        print(f"Way {way_id} is NOT blocked/tagged in the processed database (open/allowed).")
    else:
        b_name, b_hw, b_microcar, b_snaps = row_brom
        print(f"  Status:     🔴 BLOCKED (microcar: {b_microcar})")
        print(f"  Name:       {b_name}")
        print(f"  Highway:    {b_hw}")
        
        if b_snaps:
            try:
                snaps = json.loads(b_snaps)
                print(f"  Snapped C9 Signs ({len(snaps)} total):")
                for i, s in enumerate(snaps):
                    s_lat, s_lon = s.get('lat'), s.get('lon')
                    sv = make_streetview_url(s_lat, s_lon)
                    print(f"    - Sign {i+1}: Coords: ({s_lat}, {s_lon}) | Bearing: {s.get('bearing')}° | StreetView: {sv}")
            except Exception as e:
                print(f"    (Failed to parse snaps JSON: {e})")
        else:
            print("  Snapped C9 Signs: None directly listed in metadata.")

def inspect_sign(sign_id):
    print(f"\n================ INSPECTING NDW SIGN: {sign_id} ================")
    
    conn_ndw = sqlite3.connect("c9_ndw.gpkg")
    cur_ndw = conn_ndw.cursor()
    row = cur_ndw.execute("SELECT id, roadName, rvvCode, textSigns, countyName, townName, bearing, imageUrl, geom FROM c9_ndw WHERE id = ?", (str(sign_id),)).fetchone()
    
    if not row:
        print(f"NDW Sign {sign_id} not found in the database.")
        return
        
    sid, road, rvv, texts, county, town, bearing, img_url, geom = row
    lat, lon = get_lat_lon_from_gpb(geom)
    
    print("\n--- Sign Metadata ---")
    print(f"  Road Name:      {road}")
    print(f"  RVV Code:       {rvv}")
    print(f"  Text on Signs:  {texts}")
    print(f"  County/Town:    {county} / {town}")
    print(f"  Bearing:        {bearing}°")
    print(f"  Coordinates:    ({lat:.5f}, {lon:.5f})")
    print(f"  NDW Image URL:  {img_url}")
    print(f"  StreetView:     {make_streetview_url(lat, lon)}")
    
    # 2. Check where it snapped
    print("\n--- Snapping Location ---")
    conn_brom = sqlite3.connect("nl_roads_brom.gpkg")
    cur_brom = conn_brom.cursor()
    rows_brom = cur_brom.execute("SELECT osm_id, name, highway, c9_snaps FROM brom_roads WHERE c9_snaps LIKE ?", (f"%{sign_id}%",)).fetchall()
    
    if rows_brom:
        print(f"Sign successfully snapped to {len(rows_brom)} road segment(s):")
        for r in rows_brom:
            print(f"  - OSM Way {r[0]} | Name: {r[1]} | Highway: {r[2]} | {make_osm_url(r[0])}")
    else:
        print("This sign did NOT snap to any road in our pipeline (or was filtered out).")

def search_by_name(name, level0_format=False, min_speed=None, highway_types=None):
    print(f"\n================ SEARCHING FOR ROAD NAME: '{name}' ================")
    
    conn_ndw = sqlite3.connect("c9_ndw.gpkg")
    cur_ndw = conn_ndw.cursor()
    signs = cur_ndw.execute("SELECT id, roadName, townName, textSigns, geom FROM c9_ndw WHERE roadName LIKE ?", (f"%{name}%",)).fetchall()
    
    print("\n--- 1. Matching NDW C9 Signs (c9_ndw.gpkg) ---")
    if not signs:
        print("No C9 signs found matching this name.")
    else:
        print(f"Found {len(signs)} matching C9 signs:")
        for r in signs:
            lat, lon = get_lat_lon_from_gpb(r[4])
            sv = make_streetview_url(lat, lon)
            print(f"  ID: {r[0]} | Road: {r[1]} | Town: {r[2]} | Coords: ({lat:.5f}, {lon:.5f}) | StreetView: {sv}")

    conn_brom = sqlite3.connect("nl_roads_brom.gpkg")
    cur_brom = conn_brom.cursor()
    blocked = cur_brom.execute("SELECT osm_id, name, highway, microcar FROM brom_roads WHERE name LIKE ?", (f"%{name}%",)).fetchall()
    blocked_ids = {str(r[0]) for r in blocked}
    
    print("\n--- 2. Matching Blocked Roads (nl_roads_brom.gpkg) ---")
    if not blocked:
        print("No blocked roads found matching this name.")
    else:
        print(f"Found {len(blocked)} blocked/tagged road segments:")
        for r in blocked:
            print(f"  OSM ID: {r[0]} | Name: {r[1]} | Highway: {r[2]} | Microcar: {r[3]} | {make_osm_url(r[0])}")
            
    conn_raw = sqlite3.connect("nl_roads.gpkg")
    cur_raw = conn_raw.cursor()
    raw = cur_raw.execute("SELECT osm_id, name, highway, other_tags, geom FROM lines WHERE name LIKE ?", (f"%{name}%",)).fetchall()
    
    allowed = [r for r in raw if str(r[0]) not in blocked_ids]
    
    if min_speed:
        filtered_allowed = []
        for r in allowed:
            tags = str(r[3] or '')
            if f'"maxspeed"=>"{min_speed}"' in tags or f'"maxspeed"=>"{min_speed}.0"' in tags:
                filtered_allowed.append(r)
        allowed = filtered_allowed

    if highway_types:
        allowed = [r for r in allowed if r[2] in highway_types]

    print("\n--- 3. Matching Raw/Allowed Roads (nl_roads.gpkg) ---")
    if not allowed:
        print("No other matching (unrestricted) roads found.")
    else:
        print(f"Found {len(allowed)} unrestricted/open matching road segments:")
        for r in allowed:
            lat, lon = get_lat_lon_from_gpb(r[4])
            sv = make_streetview_url(lat, lon)
            print(f"  OSM ID: {r[0]} | Name: {r[1]} | Highway: {r[2]} | {make_osm_url(r[0])} | StreetView: {sv}")

        if level0_format:
            sorted_ways = sorted([int(r[0]) for r in allowed])
            formatted = ",".join([f"w{w}" for w in sorted_ways])
            print("\n=== LEVEL0 FORMAT EXPORT FOR UNRESTRICTED MATCHING WAYS ===")
            print(f"Count: {len(sorted_ways)}")
            print(formatted)

def inspect_coords(lat, lon):
    print(f"\n================ INSPECTING COORDINATES: ({lat}, {lon}) ================")
    sv_url = make_streetview_url(lat, lon)
    print(f"Location StreetView: {sv_url}")
    
    try:
        import geopandas as gpd
        from shapely.geometry import Point
        
        bbox = (lon - 0.002, lat - 0.002, lon + 0.002, lat + 0.002)
        gdf_raw = gpd.read_file("nl_roads.gpkg", bbox=bbox)
        
        if gdf_raw.empty:
            print("No roads found within 100 meters of these coordinates.")
            return
            
        pt_wgs = gpd.GeoSeries([Point(lon, lat)], crs="EPSG:4326")
        pt_rd = pt_wgs.to_crs(epsg=28992).iloc[0]
        
        gdf_raw_rd = gdf_raw.to_crs(epsg=28992)
        dists = gdf_raw_rd.geometry.distance(pt_rd)
        
        nearby = gdf_raw[dists <= 100.0]
        if nearby.empty:
            print("No roads found within 100 meters of these coordinates.")
            return
            
        closest_idx = dists.idxmin()
        closest_road = gdf_raw.loc[closest_idx]
        way_id = closest_road['osm_id']
        
        print(f"\nClosest road segment found (distance {dists.loc[closest_idx]:.2f}m):")
        print(f"  OSM Way ID: {way_id}")
        print(f"  Name:       {closest_road.get('name')}")
        print(f"  Highway:    {closest_road.get('highway')}")
        
        inspect_way(way_id)

    except ImportError:
        print("Note: Install geopandas for exact metric distance coordinate lookup.")

def main():
    parser = argparse.ArgumentParser(description="BromBrom Pipeline & Map Diagnostics CLI (High-Performance)")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-w", "--way", help="OSM Way ID to inspect")
    group.add_argument("-s", "--sign", help="NDW Sign UUID to inspect")
    group.add_argument("-n", "--name", help="Road name substring to search for")
    group.add_argument("-c", "--coords", help="Coordinates as 'lat,lon' (e.g. '52.2640,5.4724')")
    
    parser.add_argument("-p", "--pull", action="store_true", help="Force refresh of all pipeline input data first")
    parser.add_argument("-l", "--level0", action="store_true", help="Output matching way IDs in level0 format (w123,w456)")
    parser.add_argument("--min-speed", type=str, help="Filter search results by maxspeed tag (e.g. 80)")
    parser.add_argument("--highway", type=str, help="Comma-separated highway types to filter (e.g. primary,secondary)")
    
    args = parser.parse_args()
    
    if args.pull:
        pull_freshest_data()
    
    check_files(auto_pull=True)
    
    if args.way:
        inspect_way(args.way)
    elif args.sign:
        inspect_sign(args.sign)
    elif args.name:
        hw_types = [h.strip() for h in args.highway.split(',')] if args.highway else None
        search_by_name(args.name, level0_format=args.level0, min_speed=args.min_speed, highway_types=hw_types)
    elif args.coords:
        try:
            lat, lon = map(float, args.coords.split(','))
            inspect_coords(lat, lon)
        except Exception as e:
            print(f"❌ Error: Invalid coordinates format '{args.coords}'. Must be 'lat,lon'. Details: {e}")
            sys.exit(1)

if __name__ == "__main__":
    main()
