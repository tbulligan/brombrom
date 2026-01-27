#!/bin/bash
set -e

echo "=== Starting Geospatial ETL Pipeline ==="

# 1. Fetch Data
echo "[1/7] Fetching Signs..."
python scripts/fetch_nl_signs.py

echo "[2/7] Fetching Map..."
python scripts/fetch_nl_map.py

# 2. Extract Data
echo "[3/7] Extracting C9 signs..."
python scripts/extract_c9.py

echo "[4/7] Extracting Roads network..."
python scripts/extract_roads.py

# 3. Process Data
echo "[5/7] Snapping C9 to Roads..."
python scripts/snap_c9_to_roads.py

echo "[6/7] Tagging Roads in PBF..."
python scripts/tag_c9_roads.py

# 4. Generate Map
echo "[7/7] Building BRouter Segments..."
python scripts/build_brom_segments.py

echo "=== Geospatial ETL Pipeline Finished Successfully ==="
