#!/usr/bin/env python3
import json
import os
import sys
import xml.etree.ElementTree as ET
import zipfile
import geopandas as gpd

MIN_EXPECTED_OBF_SIZE_MB = 10
MIN_EXPECTED_TAGGED_ROADS = 500  # Conservative minimum; actual is usually thousands
REQUIRED_OSF_MEMBERS = {
    "items.json",
    "profile_brombrom.json",
    "routing/routing.xml",
    "NL_BromBrom_tagged.obf",
}


def validate_osf_archive(osf_path: str) -> None:
    """Verify BromBrom.osf is a valid zip containing required manifest, XML, JSON, and OBF."""
    with zipfile.ZipFile(osf_path, "r") as zf:
        names = set(zf.namelist())
        missing = REQUIRED_OSF_MEMBERS - names
        if missing:
            raise ValueError(f"OSF archive missing required entries: {sorted(missing)}")

        json.loads(zf.read("items.json"))
        json.loads(zf.read("profile_brombrom.json"))
        ET.fromstring(zf.read("routing/routing.xml"))

        obf_info = zf.getinfo("NL_BromBrom_tagged.obf")
        obf_mb = obf_info.file_size / (1024 * 1024)
        if obf_mb < MIN_EXPECTED_OBF_SIZE_MB:
            raise ValueError(f"OBF inside OSF is too small ({obf_mb:.2f} MB < {MIN_EXPECTED_OBF_SIZE_MB} MB)")


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

    try:
        ET.parse(xml_path)
    except ET.ParseError as e:
        print(f"❌ CRITICAL: Invalid XML in {xml_path}: {e}")
        sys.exit(1)

    size_mb = os.path.getsize(obf_path) / (1024 * 1024)
    print(f"Map Size: {size_mb:.2f} MB")
    
    if size_mb < MIN_EXPECTED_OBF_SIZE_MB:
        print(f"❌ CRITICAL: Map is suspiciously small (<{MIN_EXPECTED_OBF_SIZE_MB}MB). Build likely failed or data source was empty.")
        sys.exit(1)

    try:
        validate_osf_archive(osf_path)
    except Exception as e:
        print(f"❌ CRITICAL: Invalid OSF package ({osf_path}): {e}")
        sys.exit(1)
        
    # 2. Validate Tagging Logic
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
            print(f"❌ CRITICAL: Could not validate GPKG contents: {e}")
            sys.exit(1)
    else:
        print(f"❌ CRITICAL: Validation GPKG file ({gpkg_path}) not found!")
        sys.exit(1)

    print("✅ QA Validation Passed!")

if __name__ == "__main__":
    validate_build()
