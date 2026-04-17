#!/usr/bin/env python3
import os
import sys
import geopandas as gpd

MIN_EXPECTED_OBF_SIZE_MB = 100
MIN_EXPECTED_TAGGED_ROADS = 500  # Conservative minimum; actual is usually thousands

def validate_build():
    print("Running QA Validation...")
    
    # 1. Validate Artifacts
    obf_path = "OsmAndMapCreator/NL_BromBrom_tagged.obf"
    xml_path = "config/routing.xml"
    osf_path = "dist/BromBrom.osf"
    
    if not os.path.exists(obf_path):
        print(f"❌ CRITICAL: Map artifact ({obf_path}) does not exist!")
        sys.exit(1)

    if not os.path.exists(xml_path):
        print(f"❌ CRITICAL: Routing artifact ({xml_path}) does not exist!")
        sys.exit(1)
        
    if not os.path.exists(osf_path):
        print(f"❌ CRITICAL: Custom Package artifact ({osf_path}) does not exist!")
        sys.exit(1)
        
    size_mb = os.path.getsize(obf_path) / (1024 * 1024)
    print(f"Map Size: {size_mb:.2f} MB")
    
    if size_mb < MIN_EXPECTED_OBF_SIZE_MB:
        print(f"❌ CRITICAL: Map is suspiciously small (<{MIN_EXPECTED_OBF_SIZE_MB}MB). Build likely failed or data source was empty.")
        sys.exit(1)
        
    # 2. Validate Tagging Logic (if GPKG available)
    # The GPKG is the source of truth for what went into the OBF map
    gpkg_path = "nl_roads_brom.gpkg"
    if os.path.exists(gpkg_path):
        try:
            gdf = gpd.read_file(gpkg_path)
            count = len(gdf)
            print(f"Tagged Restricted Roads: {count}")
            
            if count < MIN_EXPECTED_TAGGED_ROADS:
                print(f"❌ CRITICAL: Too few roads tagged ({count}). Possible NDW API failure or empty input data.")
                sys.exit(1)
        except Exception as e:
            print(f"⚠️ Warning: Could not validate GPKG contents: {e}")
    else:
        print(f"⚠️ Warning: {gpkg_path} not found for validation.")

    print("✅ QA Validation Passed!")

if __name__ == "__main__":
    validate_build()
