#!/bin/bash
set -e

# This script downloads and builds the necessary tools for the BromBrom pipeline
# to run natively outside of Docker.

TOOLS_DIR="$(pwd)/tools"
mkdir -p "$TOOLS_DIR"

echo "========================================================"
echo "Setting up BromBrom Tools in $TOOLS_DIR"
echo "========================================================"

# 0. Check Java Dependency
if command -v java >/dev/null 2>&1; then
    JAVA_VER=$(java -version 2>&1 | head -n 1 | cut -d '"' -f 2)
    MAJOR_VER=$(echo "$JAVA_VER" | cut -d'.' -f1)
    if [[ "$MAJOR_VER" =~ ^[0-9]+$ ]] && [ "$MAJOR_VER" -lt 17 ]; then
        echo "⚠ Warning: Java version is $JAVA_VER, but OpenJDK 17+ is required to run the map compiler."
    else
        echo "✓ Java found (version $JAVA_VER)."
    fi
else
    echo "⚠ Warning: Java not found. OpenJDK 17+ is required to run the map compiler."
fi

# 1. OsmAndMapCreator (Latest Nightly)
if [ -f "$TOOLS_DIR/OsmAndMapCreator/OsmAndMapCreator.jar" ]; then
    echo "✓ OsmAndMapCreator already installed."
else
    echo "Downloading OsmAndMapCreator..."
    curl -fsSL --connect-timeout 15 --retry 5 --retry-delay 5 --retry-connrefused --speed-limit 10240 --speed-time 30 https://download.osmand.net/latest-night-build/OsmAndMapCreator-main.zip -o "$TOOLS_DIR/omc.zip"
    unzip -q "$TOOLS_DIR/omc.zip" -d "$TOOLS_DIR/OsmAndMapCreator"
    rm "$TOOLS_DIR/omc.zip"
    echo "✓ OsmAndMapCreator installed."
fi


echo "========================================================"
echo "Setup Complete!"
echo "========================================================"
