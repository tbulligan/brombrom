#!/usr/bin/env python
import geopandas as gpd
import os

# Load full NDW verkeersborden GeoJSON
ndw_path = "ndw_c9_current_state.json"
if not os.path.exists(ndw_path):
    raise FileNotFoundError(f"{ndw_path} missing - run fetch_nl_signs.py first")

if os.path.exists("c9_ndw.gpkg"):
    print("c9_ndw.gpkg already exists. Skipping.")
    exit(0)

print("Loading NDW signs...")
gdf = gpd.read_file(ndw_path)

# Filter out what is not C9 signage
print(f"Filtering {len(gdf):,} total signs...")
c9 = gdf[gdf["rvvCode"] == "C9"]
print(f"✓ Found {len(c9):,} C9 signs")

# Export
print("Writing c9_ndw.gpkg...")
c9.to_file("c9_ndw.gpkg", layer="c9_ndw", driver="GPKG", overwrite=True)
print("✓ c9_ndw.gpkg updated")
