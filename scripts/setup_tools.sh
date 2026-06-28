#!/bin/bash
set -e

# This script downloads and builds the necessary tools for the BromBrom pipeline
# to run natively outside of Docker.

TOOLS_DIR="$(pwd)/tools"
mkdir -p "$TOOLS_DIR"

echo "========================================================"
echo "Setting up BromBrom Tools in $TOOLS_DIR"
echo "========================================================"

# 1. OsmAndMapCreator (Latest Nightly)
if [ -f "$TOOLS_DIR/OsmAndMapCreator/OsmAndMapCreator.jar" ]; then
    echo "OsmAndMapCreator already present. Skipping."
else
    echo "Downloading OsmAndMapCreator..."
    wget -q http://download.osmand.net/latest-night-build/OsmAndMapCreator-main.zip -O "$TOOLS_DIR/omc.zip"
    unzip -q "$TOOLS_DIR/omc.zip" -d "$TOOLS_DIR/OsmAndMapCreator"
    rm "$TOOLS_DIR/omc.zip"
    echo "✓ OsmAndMapCreator installed."
fi


echo "========================================================"
echo "Setup Complete!"
echo "========================================================"
