# BromBrom Agent Guidelines

Dictates AI agent interaction with BromBrom repo.

## ⚡ Runtime Environment
*   **Data Processing**: Python 3.14+ (`environment.yml` dependencies) + OpenJDK 17.
*   **App Development**: Flutter stable (3.47+ / AGP 9.0+) + Android SDK/NDK v28 for native builds.
*   **Execution Strategy**:
    1.  **Native (ETL)**: Conda-like manager (`micromamba`/`conda`) with `brombrom` environment on Linux/WSL.
    2.  **Docker (Map Build)**: `Dockerfile` for map compilation.
    3.  **CI/CD (App Build)**: GitHub Actions for APK compilation.

## 🏗️ Project Architecture
Multi-component system:

### 1. Map Generation Pipeline (.osf Compilation)
*   **Python ETL**: `scripts/snap_c9_to_roads.py` core logic. Flags unsafe roads by C9 sign proximity.
*   **Java/OsmAnd Compilation**: Ingests tagged data, outputs `.obf` map.
*   **OSF Packager**: `scripts/generate_osmand_deploy.py` bundles `.obf`, `routing.xml`, and custom **Smart Profile (.json)** into `BromBrom.osf`.

### 2. BromBrom Manager (Installer App)
*   **Flutter Android App**: In `app/`.
*   **Function**: Check GitHub releases, download `BromBrom.osf`, check OsmAnd install, proxy OSF to OsmAnd via `FileProvider` intent.

## 📂 Key Files & Context
*   `app/lib/main.dart`: Android installer logic + AppLifecycle state machine.
*   `.github/workflows/build_and_release.yml`: Automation workflow. Uploads OSF release.
*   `scripts/generate_osmand_deploy.py`: Master compiler for `.osf`. Configures `profile_brombrom.json` for microcar routing.
*   `scripts/snap_c9_to_roads.py`: Road snapping core algorithm.
*   `docs/snapping_logic.md`: Spatial snapping + exemptions docs. Keep updated on snapping logic edits.

## 🚀 Release Strategy
*   **Schedule**: Weekly automated builds **Mondays 05:00 UTC**.
*   **Data Freshness & Caching**:
    *   CI caches raw datasets (OSM Netherlands extract, NDW traffic sign data).
    *   **Automated Releases**: Monday build uses cache. OSM key uses Geofabrik daily MD5 (auto-invalidates weekly). NDW key month-based (refreshes 1st build of month).
    *   **Manual Override**: `workflow_dispatch` with `force_fresh: true` forces cache-free build.
*   **Zero-Downtime**: `gh release upload --clobber` overwrites artifacts on `latest` tag.
*   **App Versioning**: Bump version in `app/pubspec.yaml` on app update (version name `n.n.n` + build number). Choose `major.minor.patch` by change scope.
*   **Commit Messages**: No generic/auto-generated messages (e.g. "Merge branch 'develop'"). Commits must be descriptive Conventional Commits scope-focused.
    *   **Merge Commits**: Use conventional commit type for combined changes (e.g. `perf(etl): integrate optimized road snapping and C9 tagging scripts` or `chore(release): integrate version check fix into main`).

## ⚠️ Known Complexities
*   **NDK Versioning**: Flutter plugins require **Android NDK 28.2.13676358**. Do not downgrade in `app/android/app/build.gradle.kts`.
*   **OsmAnd State Limitations**: OsmAnd hides new `.osf` profiles by default. Manager app uses onboarding dialogs. Do not force "visible" state via `.osf` metadata.
*   **Memory Usage**: OBF generation (Java) needs **6GB+ RAM**.

## 🧪 Testing & Validation
*   **Unit Tests**: Run pytest in micromamba:
    ```bash
    micromamba run -n brombrom pytest
    ```
    *Note: Skip Python tests for pure app or docs edits.*
*   **Graph Drills**: Run `scripts/validate_results.py` to verify map sanity + OSF artifacts.
*   **On-Demand Diagnostics**: Debug routing/data via `scripts/debug_road.py` and `scripts/diagnose_route.py` per [testing.md](file:///home/tomaso/projects/brombrom/docs/testing.md).
    *   Inspect road way: `micromamba run -n brombrom python scripts/debug_road.py --way <OSM_WAY_ID>`
    *   Simulate route: `micromamba run -n brombrom python scripts/diagnose_route.py --start <LAT,LON> --end <LAT,LON>`
*   **App Testing**: Push app changes to `develop`. Download APK artifacts from GitHub Actions before merging to `main`.

## ⏱️ Agent Execution Rules
*   **Sensible Timers**: Set background task timers (3–5 min) instead of polling.
*   **Request Reformulation**: Reformulate ambiguous requests before editing codebase.
*   **No Ad-hoc Overrides**: No local config files or custom sign/road overrides. NDW and OSM datasets remain single source of truth. Fix data upstream.
