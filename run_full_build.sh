#!/bin/bash
set -e

echo "========================================================"
echo "      BromBrom - Optimized Android Build"
echo "========================================================"

# Ensure directories exist
mkdir -p segments4
mkdir -p dist
mkdir -p osmand_input
mkdir -p osmand_output
mkdir -p osmand_gen

# 1. Run the Data & Processing Pipeline
echo ">>> [Stage 1] Data & Processing..."
# Check if python deps work
python --version
./scripts/run_pipeline.sh

# 2. OsmAnd Map Generation (OBF)
echo ">>> [Stage 2] OsmAnd OBF..."
# Clean old temp DBs that might conflict or cause OOM
rm -f OsmAndMapCreator/*.odb osmand_gen/*.odb

cp nl_brom_tagged.osm.pbf osmand_input/

# Determine OmC location (handle potential nesting from unzip)
OMC_DIR="OsmAndMapCreator"
if [ -d "/opt/OsmAndMapCreator" ]; then
    # find the actual directory containing the JAR
    ACTUAL_DIR=$(find /opt/OsmAndMapCreator -name "OsmAndMapCreator.jar" -exec dirname {} \;)
    if [ -n "$ACTUAL_DIR" ]; then
        OMC_DIR="$ACTUAL_DIR"
    fi
fi

# Run IndexBatchCreator via MainUtilities (Required for modern nightly builds)
# Increased memory to 10G since user upped WSL limits
JAVA_OPTS="-Xmx10G -Xms2G"
echo "    Running MainUtilities generate-obf-files-in-batch using $OMC_DIR ($JAVA_OPTS)..."
java -Djava.util.logging.config.file="$OMC_DIR/logging.properties" \
    $JAVA_OPTS \
    -cp "$OMC_DIR/OsmAndMapCreator.jar:$OMC_DIR/lib/*" \
    net.osmand.MainUtilities generate-obf-files-in-batch \
    config/batch_docker.xml

# Move result
mkdir -p OsmAndMapCreator
mv osmand_output/*.obf OsmAndMapCreator/

# 3. Packaging
echo ">>> [Stage 3] Packaging..."
python scripts/generate_android_deploy.py

echo "========================================================"
echo "      Build Complete!"
echo "      Artifact: dist/brombrom_android_deploy.zip"
echo "========================================================"
