# BromBrom Agent Guidelines

This file dictates how AI agents should interact with the BromBrom repository.

## ⚡ Runtime Environment
*   **Data Processing**: Python 3.14+ (with `environment.yml` dependencies) and OpenJDK 17.
*   **App Development**: Flutter 3.32.0+ (and Android SDK/NDK v27 for native builds).
*   **Execution Strategy**:
    1.  **Native (Preferred for ETL)**: Use a Conda-like manager (`micromamba`/`conda`) with the `brombrom` environment on Linux/WSL.
    2.  **Docker (Map Build)**: Use `Dockerfile` for final map compilation.
    3.  **CI/CD (App Build)**: Use GitHub Actions for APK compilation to avoid local Android SDK setup overhead.

## 🏗️ Project Architecture
BromBrom is a **multi-component system**:

### 1. Map Generation Pipeline (.osf Compilation)
*   **Python ETL**: `scripts/snap_c9_to_roads.py` is the algorithmic core. It decides which roads are "unsafe" based on spatial proximity to C9 signs.
*   **Java/OsmAnd Compilation**: Ingests tagged data and creates an `.obf` map.
*   **OSF Packager**: `scripts/generate_osmand_deploy.py` statically bundles the `.obf`, `routing.xml`, and a reverse-engineered **Smart Profile (.json)** into a pristine `BromBrom.osf` package.

### 2. BromBrom Manager (Installer App)
*   **Flutter Android App**: Located in `app/`. 
*   **Function**: Checks GitHub for the latest release, downloads `BromBrom.osf`, verifies OsmAnd installation, and securely proxies the OSF to OsmAnd via `FileProvider` intent.

## 📂 Key Files & Context
*   `app/lib/main.dart`: Core logic for the Android installer and AppLifecycle state machine.
*   `.github/workflows/build_and_release.yml`: The automation engine. Uploads the final OSF.
*   `scripts/generate_osmand_deploy.py`: Master compiler for `.osf`. The `profile_brombrom.json` contained here is hardcoded from a pristine native OsmAnd export.
*   `scripts/snap_c9_to_roads.py`: Algorithmic core affecting user safety.
*   `docs/snapping_logic.md`: Algorithmic documentation for spatial snapping and exemptions. Must be kept up to date whenever the snapping logic is modified.

## 🚀 Release Strategy
*   **Schedule**: Automated builds trigger on the **2nd of every month**.
*   **Zero-Downtime**: We use `gh release upload --clobber` to overwrite artifacts in-place on the `latest` tag. This prevents 404 errors for users during the update window.
*   **Commit Messages**: Never use generic or auto-generated commit messages (e.g., "Merge branch 'develop'"). All commit messages—especially merge commits—must be descriptive, follow the conventional commits style, and represent the feature/fix scope rather than the action of merging itself.
    *   **Merge Commits**: Do not use generic messages like `chore(merge): merge develop` or `chore(merge): merge optimized scripts`. Instead, use the appropriate conventional commit type for the combined changes, describing the feature scope (e.g., `perf(etl): integrate optimized road snapping and C9 tagging scripts` or `chore(release): integrate version check fix into main`).


## ⚠️ Known Complexities
*   **NDK Versioning**: Flutter plugins in this project require **Android NDK 27.0.12077973**. Do not downgrade in `app/android/app/build.gradle.kts`.
*   **OsmAnd State Limitations**: OsmAnd hides freshly imported `.osf` profiles by default. The Manager app mitigates this via explicit onboarding dialogs. Do not attempt to force "visible" states via `.osf` metadata.
*   **Memory Usage**: OBF generation (Java) requires **6GB+ RAM**.

## 🧪 Testing & Validation
*   **Graph Drills**: Use `scripts/validate_results.py` to verify map sanity and OSF artifact existence.
*   **App Testing**: Push app changes to `develop`. Build results can be downloaded as APK artifacts from GitHub Actions before merging to `main`.
