# BromBrom Agent Guidelines

This file dictates how AI agents should interact with the BromBrom repository.

## ⚡ Runtime Environment & Execution
## ⚡ Runtime Environment & Execution
*   **Local Python (Preferred)**: IF the user has a local `micromamba` environment named `brombrom` available, use it for Python tasks.
    *   *Check*: `micromamba env list`
    *   *Command pattern*: `micromamba run -n brombrom python scripts/your_script.py`
    *   *Why*: Faster iteration, debugging, and GIS inspection.
*   **Tool Setup**: If running locally for the first time, run `./scripts/setup_tools.sh` (within the micromamba env) to download `OsmAndMapCreator` and build `BRouter`.
*   **Docker (Fallback & Production)**: Use Docker if the local environment is missing OR for the full map compilation.
    *   *Builder Image*: `brombrom-builder`

## 🏗️ Project Architecture
BromBrom is a **hybrid pipeline**:
1.  **Python ETL (Pre-processing)**:
    *   Fetches dynamic data (NDW traffic signs, OSM PBFs).
    *   **Crucial Logic**: `scripts/snap_c9_to_roads.py` is the core intelligence. It decides which roads are "unsafe" based on spatial proximity to C9 signs.
    *   Outputs: Intermediate `.gpkg` (GeoPackage) files and tagged OSM XML/PBF.
2.  **Java/OsmAnd (Compilation)**:
    *   Ingests the tagged data.
    *   Uses `config/routing.xml` to bake routing penalties into the final `.obf` map.

## 📂 Key Files & Context
*   `config/routing.xml`: Defines the OsmAnd routing behavior. **This is not standard XML**; it is a specialized dialect for the OsmAnd routing engine.
*   `scripts/snap_c9_to_roads.py`: The high-risk algorithmic core. Changes here affect safety.
*   `debug_snaps.gpkg`: The artifact for verifying if a sign was correctly applied to a road.

## 🧪 Testing & Validation
*   **Quick Check**: Run `python scripts/validate_results.py` (via micromamba) to check if the graph looks sane.
*   **Visual Check**: Users verify `debug_snaps.gpkg` in QGIS. If an agent changes snapping logic, remind the user to visual-diff this file.
