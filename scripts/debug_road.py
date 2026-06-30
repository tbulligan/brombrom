#!/usr/bin/env python3
"""
BromBrom Diagnostic CLI Tool
============================
A command-line debugging tool to inspect the tagging pipeline status of specific roads,
signs, or search the network on-demand.

Usage:
  python scripts/debug_road.py --way <OSM_ID> [--pull]
  python scripts/debug_road.py --sign <SIGN_ID> [--pull]
  python scripts/debug_road.py --name <ROAD_NAME> [--pull]
"""
import argparse
import os
import sys
import json
import subprocess
import geopandas as gpd
import pandas as pd

def pull_freshest_data():
    print("\n================ REFRESHING PIPELINE DATA ================")
    files_to_delete = [
        "ndw_c9_current_state.json",
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
    
    # 1. Look up in the raw roads network
    print("\n--- 1. Raw OSM Road Data (nl_roads.gpkg) ---")
    gdf_raw = gpd.read_file("nl_roads.gpkg")
    way_raw = gdf_raw[gdf_raw['osm_id'].astype(str) == str(way_id)]
    
    if way_raw.empty:
        print(f"Way {way_id} not found in the raw road database.")
    else:
        row = way_raw.iloc[0]
        print(f"  Name:       {row.get('name')}")
        print(f"  Highway:    {row.get('highway')}")
        print(f"  Other Tags: {row.get('other_tags')}")
        print(f"  Geometry:   {row.geometry}")
        
    # 2. Look up in the BromBrom processed network
    print("\n--- 2. Processed/Blocked Road Data (nl_roads_brom.gpkg) ---")
    gdf_brom = gpd.read_file("nl_roads_brom.gpkg")
    way_brom = gdf_brom[gdf_brom['osm_id'].astype(str) == str(way_id)]
    
    if way_brom.empty:
        print(f"Way {way_id} is NOT blocked/tagged in the processed database (open/allowed).")
    else:
        row = way_brom.iloc[0]
        print(f"  Status:     🔴 BLOCKED (microcar: no / motor_vehicle: no)")
        print(f"  Name:       {row.get('name')}")
        print(f"  Highway:    {row.get('highway')}")
        print(f"  Exemptions: {row.get('exempt')}")
        
        snaps_str = row.get('c9_snaps')
        if snaps_str and not pd.isna(snaps_str):
            try:
                snaps = json.loads(snaps_str)
                print(f"  Snapped C9 Signs ({len(snaps)} total):")
                for i, s in enumerate(snaps):
                    print(f"    - Sign {i+1}: Coords: ({s.get('lat')}, {s.get('lon')}) | Bearing: {s.get('bearing')}°")
            except Exception as e:
                print(f"    (Failed to parse snaps JSON: {e})")
        else:
            print("  Snapped C9 Signs: None directly listed in metadata.")

def inspect_sign(sign_id):
    print(f"\n================ INSPECTING NDW SIGN: {sign_id} ================")
    
    # 1. Look up in the NDW database
    gdf_ndw = gpd.read_file("c9_ndw.gpkg")
    sign = gdf_ndw[gdf_ndw['id'] == sign_id]
    
    if sign.empty:
        print(f"NDW Sign {sign_id} not found in the database.")
        return
        
    row = sign.iloc[0]
    print("\n--- Sign Metadata ---")
    print(f"  Road Name:      {row.get('roadName')}")
    print(f"  RVV Code:       {row.get('rvvCode')}")
    print(f"  Text on Signs:  {row.get('textSigns')}")
    print(f"  County/Town:    {row.get('countyName')} / {row.get('townName')}")
    print(f"  Bearing:        {row.get('bearing')}°")
    print(f"  Coordinates:    ({row.geometry.y}, {row.geometry.x})")
    print(f"  NDW Image URL:  {row.get('imageUrl')}")
    
    # 2. Check where it snapped
    print("\n--- Snapping Location ---")
    gdf_brom = gpd.read_file("nl_roads_brom.gpkg")
    snapped_ways = []
    
    # Check by coordinates matching (or sign ID if we parse it)
    sign_lon, sign_lat = row.geometry.x, row.geometry.y
    for idx, r in gdf_brom.iterrows():
        snaps_str = r.get('c9_snaps')
        if snaps_str and not pd.isna(snaps_str):
            try:
                snaps = json.loads(snaps_str)
                for s in snaps:
                    if abs(s.get('lon') - sign_lon) < 0.0001 and abs(s.get('lat') - sign_lat) < 0.0001:
                        snapped_ways.append({
                            'osm_id': r['osm_id'],
                            'name': r['name'],
                            'highway': r['highway']
                        })
            except Exception:
                pass
                
    if snapped_ways:
        print(f"Sign successfully snapped to {len(snapped_ways)} road segment(s):")
        for w in snapped_ways:
            print(f"  - OSM Way {w['osm_id']} | Name: {w['name']} | Highway: {w['highway']}")
    else:
        print("This sign did NOT snap to any road in our pipeline (or was filtered out).")

def search_by_name(name):
    print(f"\n================ SEARCHING FOR ROAD NAME: '{name}' ================")
    
    # 1. Search in NDW signs
    print("\n--- 1. Matching NDW C9 Signs (c9_ndw.gpkg) ---")
    gdf_ndw = gpd.read_file("c9_ndw.gpkg")
    matching_signs = gdf_ndw[gdf_ndw['roadName'].fillna('').str.contains(name, case=False)]
    
    if matching_signs.empty:
        print("No C9 signs found matching this name.")
    else:
        print(f"Found {len(matching_signs)} matching C9 signs:")
        for idx, row in matching_signs.iterrows():
            print(f"  ID: {row['id']} | Road: {row['roadName']} | Town: {row['townName']} | Coords: ({row.geometry.y:.5f}, {row.geometry.x:.5f})")
            
    # 2. Search in processed blocked roads
    print("\n--- 2. Matching Blocked Roads (nl_roads_brom.gpkg) ---")
    gdf_brom = gpd.read_file("nl_roads_brom.gpkg")
    matching_brom = gdf_brom[gdf_brom['name'].fillna('').str.contains(name, case=False)]
    
    if matching_brom.empty:
        print("No blocked roads found matching this name.")
    else:
        print(f"Found {len(matching_brom)} blocked/tagged road segments:")
        for idx, row in matching_brom.iterrows():
            print(f"  OSM ID: {row['osm_id']} | Name: {row['name']} | Highway: {row['highway']} | Exempt: {row.get('exempt')}")
            
    # 3. Search in raw roads (to show allowed ones)
    print("\n--- 3. Matching Raw/Allowed Roads (nl_roads.gpkg) ---")
    gdf_raw = gpd.read_file("nl_roads.gpkg")
    matching_raw = gdf_raw[gdf_raw['name'].fillna('').str.contains(name, case=False)]
    
    blocked_ids = set(matching_brom['osm_id'].astype(str))
    allowed_roads = matching_raw[~matching_raw['osm_id'].astype(str).isin(blocked_ids)]
    
    if allowed_roads.empty:
        print("No other matching (unrestricted) roads found.")
    else:
        print(f"Found {len(allowed_roads)} unrestricted/open matching road segments:")
        for idx, row in allowed_roads.iterrows():
            print(f"  OSM ID: {row['osm_id']} | Name: {row['name']} | Highway: {row['highway']}")

def main():
    parser = argparse.ArgumentParser(description="BromBrom Pipeline & Map Diagnostics CLI")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-w", "--way", help="OSM Way ID to inspect")
    group.add_argument("-s", "--sign", help="NDW Sign UUID to inspect")
    group.add_argument("-n", "--name", help="Road name substring to search for")
    
    parser.add_argument("-p", "--pull", action="store_true", help="Force refresh of all pipeline input data first")
    
    args = parser.parse_args()
    
    if args.pull:
        pull_freshest_data()
    
    check_files(auto_pull=True)
    
    # ponytail: Keep command execution and dispatch boringly simple
    if args.way:
        inspect_way(args.way)
    elif args.sign:
        inspect_sign(args.sign)
    elif args.name:
        search_by_name(args.name)

if __name__ == "__main__":
    main()
