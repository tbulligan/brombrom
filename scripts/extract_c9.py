#!/usr/bin/env python3
import geopandas as gpd
import os

try:
    from snap_c9_to_roads import has_microcar_exemption
except ImportError:
    from scripts.snap_c9_to_roads import has_microcar_exemption

def main():
    # Load full NDW verkeersborden GeoJSON
    ndw_path = "ndw_current_state.json"
    if not os.path.exists(ndw_path):
        raise FileNotFoundError(f"{ndw_path} missing - run fetch_nl_signs.py first")

    if os.path.exists("c9_ndw.gpkg") and os.path.exists("g_exemptions_ndw.gpkg"):
        print("c9_ndw.gpkg and g_exemptions_ndw.gpkg already exist. Skipping.")
        return

    print("Loading NDW signs...")
    gdf = gpd.read_file(ndw_path)

    print(f"Filtering {len(gdf):,} total signs...")
    c9 = gdf[gdf["rvvCode"] == "C9"]
    print(f"✓ Found {len(c9):,} C9 signs")

    # Extract microcar exemption signs for G12a, G11, C12, and C9
    cand_codes = ["G12a", "G11", "C12", "C9"]
    cand_gdf = gdf[gdf["rvvCode"].isin(cand_codes)].copy()
    ex_mask = cand_gdf.apply(has_microcar_exemption, axis=1)
    g_exemptions = cand_gdf[ex_mask].copy()
    print(f"✓ Found {len(g_exemptions):,} microcar exemption signs across G12a/G11/C12/C9")

    # Export
    print("Writing c9_ndw.gpkg and g_exemptions_ndw.gpkg...")
    c9.to_file("c9_ndw.gpkg", layer="c9_ndw", driver="GPKG", overwrite=True)
    g_exemptions.to_file("g_exemptions_ndw.gpkg", layer="g_exemptions_ndw", driver="GPKG", overwrite=True)
    print("✓ Spatial sign datasets updated")

if __name__ == "__main__":
    main()

