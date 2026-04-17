# BromBrom Agent Guidelines

This file dictates how AI agents should interact with the BromBrom repository.

## ⚡ Runtime Environment
*   **Data Processing**: Python 3.14+ (with `environment.yml` dependencies) and OpenJDK 17.
*   **App Development**: Flutter 3.27.0+ (and Android SDK/NDK v27 for native builds).
*   **Execution Strategy**:
    1.  **Native (Preferred for ETL)**: Use a Conda-like manager (`micromamba`/`conda`) with the `brombrom` environment on Linux/WSL.
    2.  **Docker (Map Build)**: Use `Dockerfile` for final map compilation.
    3.  **CI/CD (App Build)**: Use GitHub Actions for APK compilation to avoid local Android SDK setup overhead.

## 🏗️ Project Architecture
BromBrom is a **multi-component system**:

### 1. Map Generation Pipeline
*   **Python ETL**: `scripts/snap_c9_to_roads.py` is the algorithmic core. It decides which roads are "unsafe" based on spatial proximity to C9 signs.
*   **Java/OsmAnd Compilation**: Ingests tagged data and uses `config/routing.xml` to bake routing penalties into the final `.obf` map.

### 2. BromBrom Manager (Installer App)
*   **Flutter Android App**: Located in `app/`. 
*   **Function**: Checks GitHub for the latest release, downloads the `.obf` file, and triggers an import intent in OsmAnd via a secure `FileProvider`.

## 📂 Key Files & Context
*   `app/lib/main.dart`: Core logic for the Android installer (Bilingual NL/EN).
*   `.github/workflows/build_and_release.yml`: The automation engine. Handles Zero-Downtime map updates and APK builds.
*   `config/routing.xml`: Defines the OsmAnd routing behavior. **Do not refactor blindly.**
*   `scripts/snap_c9_to_roads.py`: Algorithmic core affecting user safety.

## 🚀 Release Strategy
*   **Schedule**: Automated builds trigger on the **2nd of every month**.
*   **Zero-Downtime**: We use `gh release upload --clobber` to overwrite artifacts in-place on the `latest` tag. This prevents 404 errors for users during the update window.
*   **Tagging**: The git tag `latest` is force-moved to the most recent map build on every successful CI run.

## ⚠️ Known Complexities
*   **NDK Versioning**: Flutter plugins in this project require **Android NDK 27.0.12077973**. Do not downgrade in `app/android/app/build.gradle.kts`.
*   **Memory Usage**: OBF generation (Java) requires **6GB+ RAM**.
*   **OsmAnd FileProvider**: The app shares files with OsmAnd via `content://` URIs. Manifest changes to `<provider>` must remain inside the `<application>` block.

## 🧪 Testing & Validation
*   **Graph Drills**: Use `scripts/validate_results.py` to verify map sanity.
*   **App Testing**: Push app changes to `develop`. Build results can be downloaded as APK artifacts from GitHub Actions before merging to `main`.
