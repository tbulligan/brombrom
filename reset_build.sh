#!/bin/bash
# BromBrom - Fast Build Artifact Reset
# Cleans derived geospatial, tagging, and OsmAnd build outputs to trigger a fast rebuild
# WITHOUT deleting downloaded raw datasets (OSM map, NDW signs, base nl_roads.gpkg) or tools.

echo "Resetting BromBrom build outputs (preserving raw data & tools)..."

# Derived geospatial processing outputs
rm -f nl_roads_brom.gpkg
rm -f debug_snaps.gpkg
rm -f missed_c9.gpkg
rm -f c9_exemptions.gpkg
rm -f g_exemptions_ways.json

# Processed map artifacts & deployment packages
rm -f NL_BromBrom_tagged.osm.pbf
rm -f OsmAndMapCreator/*.obf
rm -f OsmAndMapCreator/*.odb
rm -rf dist/

# Temporary build workspace folders
rm -rf osmand_input/*
rm -rf osmand_output/*
rm -rf osmand_gen/*
rm -rf temp_map_build/
rm -rf temp_map_test/
rm -rf segments4/

# Build logs & Python bytecode caches
rm -f build_log.txt
rm -f *.log
rm -rf .pytest_cache/
find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
find . -type f -name '*.pyc' -exec rm -f {} + 2>/dev/null || true

echo "✓ Build outputs reset. Base datasets (OSM map, NDW signs, nl_roads.gpkg) and tools preserved."
