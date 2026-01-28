#!/bin/bash
set -e

echo "========================================================"
echo "      BromBrom - OsmAnd Navigation Build"
echo "========================================================"

# Pre-flight checks & Cleanup
mkdir -p segments4 dist osmand_input osmand_output osmand_gen
rm -f OsmAndMapCreator/*.odb osmand_gen/*.odb osmand_output/*.obf

# Stage 1: Processing (Steps 1-6)
./scripts/run_pipeline.sh

# Stage 2: Map Generation (Steps 7-8)
if ls OsmAndMapCreator/NL_BromBrom_tagged.obf >/dev/null 2>&1; then
    echo "[7/9] OsmAnd OBF Map already exists. Skipping."
else
    echo "[7/9] Generating OsmAnd OBF Map..."
    # Clean output, input, and gen to start fresh if building
    rm -rf osmand_output/*
    rm -rf osmand_gen/*
    rm -f OsmAndMapCreator/*.obf
    rm -f osmand_input/*.osm.pbf
    cp NL_BromBrom_tagged.osm.pbf osmand_input/

    # ... (OMC_DIR logic omitted for brevity in target but will be preserved)
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
    # Move and force rename to the requested name
    # We take any .obf generated (likely NL_BromBrom_tagged.obf) and ensure the name
    find osmand_output/ -name "*.obf" -exec mv {} OsmAndMapCreator/NL_BromBrom_tagged.obf \;
fi

# Optional: Developer Debug Mode
if [ "$DEBUG" = "true" ]; then
    echo "[8/9] DEBUG mode active: Generating BRouter Segments..."
    python3 scripts/build_brom_segments.py
else
    echo "[8/9] Skipping Developer features (DEBUG != true)."
fi

# Stage 3: Deployment (Step 9)
echo "[9/9] Creating OsmAnd Deployment Package..."
python3 scripts/generate_osmand_deploy.py

# Stage 4: QA Validation
echo "[QA] Validating Results..."
python3 scripts/validate_results.py

echo "========================================================"
echo "      Build Successful!"
echo "      Output: dist/brombrom_osmand_deploy.zip"
echo "========================================================"
