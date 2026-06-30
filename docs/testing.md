# Testing & Quality Assurance

This project includes a suite of unit tests and validation scripts to ensure the accuracy of the microcar restriction logic.

## Unit Tests

Unit tests are located in the `tests/` directory and focus on the core algorithms used in the ETL pipeline.

### Coverage
- **Exemption Logic**: Validates that traffic signs are correctly identified as having microcar exemptions (e.g., `OB65`, `uitgezonderd brommobielen`), including handling of common OCR typos.
- **Bearing Calculation**: Ensures that directional snapping correctly calculates angles between points.
- **Geometric Side Detection**: Validates the cross-product logic used to determine if a sign is on the left or right of a road segment.

### Running Tests
To run the unit tests, use the standard Python `unittest` module from the project root:

```bash
# Using the project's recommended environment
pytest
```

## Validation & Results QC

In addition to unit tests, the `run_full_build.sh` pipeline includes a QA validation step:

1. **`validate_results.py`**: Automatically runs at the end of every build to check the integrity of the generated `.obf` and `.pbf` files.
2. **Debug Mode**: Running with `DEBUG=true` generates several geospatial artifacts for inspection:
    *   `debug_snaps.gpkg`: Lines connecting C9 signs to their snapped road locations.
    *   `analysis_snaps.gpkg`: All successfully snapped signs with metadata (ratio, road length).
    *   `nl_roads_brom.gpkg`: Roads that are blocked in their entirety.
    *   `c9_exemptions.gpkg`: Signs ignored due to detected brommobiel exemptions.

3. **Forced Rebuild**: Running with `FORCE_REBUILD=true` allows you to re-run the geospatial processing (snapping) logic even if the intermediary files (like `nl_roads_brom.gpkg`) already exist. This is useful for testing logic changes without performing a full `./clean.sh` which would delete your downloaded base maps.

## On-Demand Diagnostics

For debugging specific routing complaints or verifying local data, a command-line diagnostic tool is available in [debug_road.py](file:///home/tomaso/projects/brombrom/scripts/debug_road.py).

It queries the raw road database (`nl_roads.gpkg`), the blocked road database (`nl_roads_brom.gpkg`), and the NDW signs database (`c9_ndw.gpkg`) to report metadata, snapped signs, and tags.

### Usage

```bash
# Query a specific OSM Way ID to see its metadata, tags, and snapped signs
python scripts/debug_road.py --way <OSM_WAY_ID>

# Query a specific NDW Sign UUID to see its attributes, image URL, and where it snapped
python scripts/debug_road.py --sign <SIGN_UUID>

# Search for roads and C9 signs by name (case-insensitive substring)
python scripts/debug_road.py --name <ROAD_NAME>

# Find the closest road segment to a coordinate and inspect it
python scripts/debug_road.py --coords <LAT,LON>

# Force a full refresh (re-download and extract) of the freshest NDW/OSM data before analysis
python scripts/debug_road.py --name <ROAD_NAME> --pull
```

If the required geopackage databases are missing when running a query, the tool will automatically pull and rebuild them for you out-of-the-box.

## Visual Inspection with QGIS

Use [QGIS](https://qgis.org/) (Free and Open Source GIS) to verify that the logic correctly identifies and splits roads.

### Setup
1.  **Background Map**: Add OpenStreetMap in the Browser panel under `XYZ Tiles > OpenStreetMap`.
2.  **Import Files**: Drag and drop the `.gpkg` files listed above into QGIS.
3.  **Coordinate System**: The data is in **RD New (EPSG:28992)**. If QGIS asks for a transformation operation, select the one for the "Netherlands - onshore" with the highest accuracy.
4.  **WSL Tip**: If you are running QGIS on Windows and the files are in WSL (`\\wsl.localhost\...`), SQLite/GeoPackage file locking may cause an "Invalid Data Source" error. **Copy the files to a native Windows folder** (e.g., Desktop) before opening.

### What to check
- **Snap Links (`debug_snaps`)**: Ensure the lines are short (usually < 5m). Long diagonal lines indicate signs snapped to the wrong parallel road or overpasses.
- **Way Splitting (Visual Identification)**: 
    1.  Open `analysis_snaps` Properties > **Symbology**.
    2.  At the **very top of the window**, click the dropdown (which defaults to **Single Symbol**) and change it to **Graduated**. (Do not confuse this with the "Symbol Layer Type" dropdown inside the marker settings).
    3.  Set **Value** to `ratio` and click **Classify** (located at the bottom of the classes list).
    4.  Signs with values near **0.5** sit in the middle of a segment and are prime candidates for verifying the splitting logic. Verify that the matching `debug_snaps` line targets the middle of a street segment.
- **Restricted Roads (`nl_roads_brom`)**: Overlay these on top of the map to see exactly which segments are fully forbidden for navigation.

## Continuous Integration
Tests are automatically executed on every push to the `develop` and `main` branches via GitHub Actions using `pytest`.
