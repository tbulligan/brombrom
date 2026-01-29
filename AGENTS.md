# BromBrom Agent Guidelines

This file dictates how AI agents should interact with the BromBrom repository.

## ⚡ Runtime Environment
*   **Requirement**: Python 3.14+ (with `environment.yml` dependencies) and OpenJDK 17.
*   **Execution Strategy**:
    1.  **Native (Preferred for Dev)**: Use a Conda-like manager (`micromamba`/`conda`) with the `brombrom` environment.
    2.  **Windows/WSL Caveat**: Geospatial libraries (GDAL, Fiona) are notoriously fragile on native Windows. Execution via WSL is highly recommended for stability.
    3.  **Docker (Full Build)**: Use `Dockerfile` for the final map compilation or if local environment setup fails.
*   **Command Logic**: Agents should detect the current shell. If on Windows and a WSL `brombrom` env is present, use: `wsl bash -l -c "micromamba run -n brombrom python3 ..."`

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
*   `config/routing.xml`: Defines the OsmAnd routing behavior.
*   `scripts/snap_c9_to_roads.py`: The high-risk algorithmic core. Changes here affect safety.
*   `debug_snaps.gpkg`: The artifact for verifying if a sign was correctly applied to a road.

## ⚠️ Known Complexities
*   **OsmAnd XML Dialect**: `config/routing.xml` is a specialized dialect for the OsmAnd engine. It is NOT standard XML; do not "clean" or refactor it using general XML rules.
*   **Memory Usage**: OBF generation (Java) requires **6GB+ RAM**. Ensure the environment/container has sufficient allocation.
*   **Idempotency**: The build script skips finished stages. Use `./clean.sh` if logic changes require a full re-run.

## 🧪 Testing & Validation
*   **Check Script**: Use `scripts/validate_results.py` to verify the graph sanity.
*   **Visual Diff**: Any changes to `scripts/snap_c9_to_roads.py` require a visual audit of `debug_snaps.gpkg` in QGIS to ensure snapping orientation hasn't flipped.
