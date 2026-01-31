#!/bin/bash
# BromBrom - Project Workspace Reset
# This script removes all data artifacts, maps, and temporary tool installations.

echo "Cleaning project to pristine state..."

# We use a Docker helper to ensure we have permissions to remove files
# created by the builder container (which runs as root).
# Note: We NEVER clean the tests/ directory as they are critical for QA
docker run --rm -v "$(pwd):/app" -w /app alpine sh -c "rm -rf \
    dist/ \
    segments4/ \
    osmand_input/ \
    osmand_output/ \
    osmand_gen/ \
    temp_map_build/ \
    temp_map_test/ \
    srtm/ \
    tools/ \
    *.pbf \
    *.gpkg \
    *.json \
    *.odb \
    *.ocbf \
    *.obf \
    OsmAndMapCreator/*.obf \
    *.log"

echo "✓ Workspace is pristine."
