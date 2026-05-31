#!/usr/bin/env python3
import os
import subprocess
from pathlib import Path
from osgeo import gdal  # Triggers GDAL init

PBF_IN = "nl_map.osm.pbf"
PBF_OUT = "nl_roads.osm.pbf"
GPKG_OUT = "nl_roads.gpkg"

if os.path.exists(GPKG_OUT):
    print(f"{GPKG_OUT} already exists. Skipping.")
    exit(0)

print("Filtering roads...")
subprocess.run([
    "osmium", "tags-filter", PBF_IN,
    "w/highway=primary,primary_link,secondary,secondary_link,tertiary,tertiary_link,residential,unclassified,trunk,trunk_link,motorway,motorway_link,living_street,service,road,track",
    "r/type=restriction,restriction:conditional",
    "-o", PBF_OUT, "--overwrite",
], check=True)

print("Converting to GeoPackage...")
subprocess.run([
    "ogr2ogr", "-f", "GPKG", GPKG_OUT, PBF_OUT, "lines"
], check=True)

print(f"✓ {GPKG_OUT} created")
