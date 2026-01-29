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
    echo "[1/2] OsmAndMapCreator already present. Skipping."
else
    echo "[1/2] Downloading OsmAndMapCreator..."
    wget -q http://download.osmand.net/latest-night-build/OsmAndMapCreator-main.zip -O "$TOOLS_DIR/omc.zip"
    unzip -q "$TOOLS_DIR/omc.zip" -d "$TOOLS_DIR/OsmAndMapCreator"
    rm "$TOOLS_DIR/omc.zip"
    echo "✓ OsmAndMapCreator installed."
fi

# 2. BRouter (Build from source)
if [ -f "$TOOLS_DIR/brouter/brouter-server/build/libs/brouter-1.7.8-all.jar" ]; then
    echo "[2/2] BRouter already present. Skipping."
else
    echo "[2/2] Building BRouter from source..."
    BR_SRC="$TOOLS_DIR/brouter_src"
    rm -rf "$BR_SRC"
    git clone --depth 1 https://github.com/abrensch/brouter.git "$BR_SRC"
    
    cd "$BR_SRC"
    ./gradlew :brouter-server:fatJar
    
    mkdir -p "$TOOLS_DIR/brouter/brouter-server/build/libs/"
    mkdir -p "$TOOLS_DIR/brouter/misc/profiles2/"
    
    cp brouter-server/build/libs/brouter-*-all.jar "$TOOLS_DIR/brouter/brouter-server/build/libs/brouter-1.7.8-all.jar"
    cp -r misc/profiles2/* "$TOOLS_DIR/brouter/misc/profiles2/"
    
    cd - > /dev/null
    rm -rf "$BR_SRC"
    echo "✓ BRouter built and installed."
fi

echo "========================================================"
echo "Setup Complete!"
echo "========================================================"
