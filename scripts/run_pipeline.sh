#!/bin/bash
set -e

# Data Acquisition
echo "[1/9] Fetching Traffic Sign Data (NDW)..."
python3 scripts/fetch_nl_signs.py

echo "[2/9] Fetching Map Data (OSM)..."
python3 scripts/fetch_nl_map.py

# Data Extraction
echo "[3/9] Extracting C9 restrictions..."
python3 scripts/extract_c9.py

echo "[4/9] Extracting road network..."
python3 scripts/extract_roads.py

# Geospatial Processing
echo "[5/9] Snapping restrictions to road network..."
python3 scripts/snap_c9_to_roads.py

echo "[6/9] Applying custom tags to PBF..."
python3 scripts/tag_c9_roads.py
