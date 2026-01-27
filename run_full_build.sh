#!/bin/bash
set -e

echo "========================================================"
echo "      BromBrom - Android Deployment Build"
echo "========================================================"

# Pre-flight checks & Cleanup
mkdir -p segments4 dist osmand_input osmand_output osmand_gen
rm -f OsmAndMapCreator/*.odb osmand_gen/*.odb

# Stage 1: Processing (Steps 1-6)
./scripts/run_pipeline.sh

# Stage 2: Map Generation (Steps 7-8)
if ls OsmAndMapCreator/*.obf >/dev/null 2>&1; then
    echo "[7/9] OsmAnd OBF Map already exists. Skipping."
else
    echo "[7/9] Generating OsmAnd OBF Map..."
    cp nl_brom_tagged.osm.pbf osmand_input/

    # Dynamically locate OsmAndMapCreator
    OMC_DIR="OsmAndMapCreator"
    if [ -d "/opt/OsmAndMapCreator" ]; then
        ACTUAL_DIR=$(find /opt/OsmAndMapCreator -name "OsmAndMapCreator.jar" -exec dirname {} \;)
        [ -n "$ACTUAL_DIR" ] && OMC_DIR="$ACTUAL_DIR"
    fi

    # Run OsmAndMapCreator
    JAVA_OPTS="-Xmx6G -Xms2G"
    java -Djava.util.logging.config.file="$OMC_DIR/logging.properties" \
        $JAVA_OPTS \
        -cp "$OMC_DIR/OsmAndMapCreator.jar:$OMC_DIR/lib/*" \
        net.osmand.MainUtilities generate-obf-files-in-batch \
        config/batch_docker.xml

    mkdir -p OsmAndMapCreator
    mv osmand_output/*.obf OsmAndMapCreator/
fi

# Optional: BRouter
if [ "$INCLUDE_BROUTER" = "true" ]; then
    echo "[8/9] Generating BRouter Segments..."
    python3 scripts/build_brom_segments.py
else
    echo "[8/9] Skipping BRouter generation (Optional)."
fi

# Stage 3: Deployment (Step 9)
echo "[9/9] Creating OsmAnd Deployment Package..."
python3 scripts/generate_osmand_deploy.py

echo "========================================================"
echo "      Build Successful!"
echo "      Output: dist/brombrom_osmand_deploy.zip"
echo "========================================================"
