#!/bin/bash
set -e

echo "========================================================"
echo "      BromBrom - OsmAnd Navigation Build"
echo "========================================================"

# Pre-flight checks & Cleanup
if ! command -v java >/dev/null 2>&1; then
    echo "Error: java command not found. Please install Java 17+."
    exit 1
fi

# Locate OsmAndMapCreator
OMC_DIR=""
for candidate in "tools/OsmAndMapCreator" "/opt/OsmAndMapCreator" "OsmAndMapCreator"; do
    if [ -d "$candidate" ]; then
        JAR=$(find "$candidate" -name "OsmAndMapCreator.jar" -print -quit 2>/dev/null)
        if [ -n "$JAR" ]; then
            OMC_DIR=$(dirname "$JAR")
            break
        fi
    fi
done

if [ -z "$OMC_DIR" ]; then
    echo "Error: OsmAndMapCreator.jar not found."
    echo "Please run './scripts/setup_tools.sh' to install dependencies."
    exit 1
fi

mkdir -p segments4 dist osmand_input osmand_output osmand_gen
rm -f OsmAndMapCreator/*.odb osmand_gen/*.odb osmand_output/*.obf

# Stage 1: Processing (Steps 1-6)
./scripts/run_pipeline.sh

# Stage 2: Map Generation (Step 7)
if ls OsmAndMapCreator/NL_BromBrom_tagged.obf >/dev/null 2>&1; then
    echo "[7/8] OsmAnd OBF Map already exists. Skipping."
else
    echo "[7/8] Generating OsmAnd OBF Map..."
    # Clean output, input, and gen to start fresh if building
    rm -rf osmand_output/*
    rm -rf osmand_gen/*
    rm -f OsmAndMapCreator/*.obf
    rm -f osmand_input/*.osm.pbf
    cp NL_BromBrom_tagged.osm.pbf osmand_input/
    # Run OsmAndMapCreator
    JAVA_OPTS="-Xmx4800m -Xms2000m -XX:+UseG1GC -XX:+UseStringDeduplication"
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

# Stage 3: Deployment (Step 8)
echo "[8/8] Creating OsmAnd Deployment Package..."
python3 scripts/generate_osmand_deploy.py

# Stage 4: QA Validation
echo "[QA] Validating Results..."
python3 scripts/validate_results.py

echo "========================================================"
echo "      Build Successful!"
echo "      Output: dist/"
echo "========================================================"
