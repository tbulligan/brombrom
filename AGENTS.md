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
*   **OSF Packager**: `scripts/generate_osmand_deploy.py` statically bundles the `.obf`, `routing.xml`, and a customized **Smart Profile (.json)** into a pristine `BromBrom.osf` package.

### 2. BromBrom Manager (Installer App)
*   **Flutter Android App**: Located in `app/`. 
*   **Function**: Checks GitHub for the latest release, downloads `BromBrom.osf`, verifies OsmAnd installation, and securely proxies the OSF to OsmAnd via `FileProvider` intent.

## 📂 Key Files & Context
*   `app/lib/main.dart`: Core logic for the Android installer and AppLifecycle state machine.
*   `.github/workflows/build_and_release.yml`: The automation engine. Uploads the final OSF.
*   `scripts/generate_osmand_deploy.py`: Master compiler for `.osf`. The `profile_brombrom.json` generated here is custom-configured for optimized microcar navigation.
*   `scripts/snap_c9_to_roads.py`: Algorithmic core affecting user safety.
*   `docs/snapping_logic.md`: Algorithmic documentation for spatial snapping and exemptions. Must be kept up to date whenever the snapping logic is modified.

## 🚀 Release Strategy
*   **Schedule**: Automated builds trigger weekly on **Mondays at 05:00 UTC**.
*   **Data Freshness & Caching**: 
    *   To keep builds fast, raw external datasets (OSM Netherlands extract and NDW traffic sign data) are cached in CI.
    *   **Automated Releases**: The weekly Monday release utilizes the cache. Since the OSM cache key is derived from Geofabrik's daily MD5 checksum, it naturally invalidates and downloads a fresh map on the weekly build. The NDW cache key is month-based, meaning the weekly build will restore NDW from cache (saving ~1.18 GB of download) and only pull it fresh on the first build of each month.
    *   **Manual Override**: Developers triggering manual builds via `workflow_dispatch` can force a fresh cache-free compile by setting the `force_fresh` input to `true`.
*   **Zero-Downtime**: We use `gh release upload --clobber` to overwrite artifacts in-place on the `latest` tag. This prevents 404 errors for users during the update window.
*   **App Versioning**: Always increase the version number in `app/pubspec.yaml` whenever you update the app (both the version name `n.n.n` and the build number after the `+`). Decide which component of the version number (`major.minor.patch`) to increase based on the nature of the changes (e.g., bump patch for bug fixes, minor for new backward-compatible features, major for breaking changes).
*   **Commit Messages**: Never use generic or auto-generated commit messages (e.g., "Merge branch 'develop'"). All commit messages—especially merge commits—must be descriptive, follow the conventional commits style, and represent the feature/fix scope rather than the action of merging itself.
    *   **Merge Commits**: Do not use generic messages like `chore(merge): merge develop` or `chore(merge): merge optimized scripts`. Instead, use the appropriate conventional commit type for the combined changes, describing the feature scope (e.g., `perf(etl): integrate optimized road snapping and C9 tagging scripts` or `chore(release): integrate version check fix into main`).


## ⚠️ Known Complexities
*   **NDK Versioning**: Flutter plugins in this project require **Android NDK 27.0.12077973**. Do not downgrade in `app/android/app/build.gradle.kts`.
*   **OsmAnd State Limitations**: OsmAnd hides freshly imported `.osf` profiles by default. The Manager app mitigates this via explicit onboarding dialogs. Do not attempt to force "visible" states via `.osf` metadata.
*   **Memory Usage**: OBF generation (Java) requires **6GB+ RAM**.

## 🧪 Testing & Validation
*   **Unit Tests**: Run unit tests via pytest inside the micromamba environment:
    ```bash
    micromamba run -n brombrom pytest
    ```
    *Note: Skip Python test runs for pure app or website UI/text modifications to save time.*
*   **Graph Drills**: Use `scripts/validate_results.py` to verify map sanity and OSF artifact existence.
*   **On-Demand Diagnostics**: For debugging specific routing complaints or verifying local data, use `scripts/debug_road.py` and `scripts/diagnose_route.py` as detailed in [testing.md](file:///home/tomaso/projects/brombrom/docs/testing.md).
    *   Inspect a road way: `micromamba run -n brombrom python scripts/debug_road.py --way <OSM_WAY_ID>`
    *   Simulate a route: `micromamba run -n brombrom python scripts/diagnose_route.py --start <LAT,LON> --end <LAT,LON>`
*   **App Testing**: Push app changes to `develop`. Build results can be downloaded as APK artifacts from GitHub Actions before merging to `main`.

## ⏱️ Agent Execution Rules
*   **Sensible Timers**: When launching long-running background tasks (such as map compilation or downloads), set schedule timers for a sensible duration (e.g. 3–5 minutes) rather than polling frequently, to prevent excessive wakeups and optimize token usage.
*   **Request Reformulation**: If a user request is ambiguous or needs clarification, explicitly reformulate the goal in your response to confirm alignment before proceeding to make codebase edits.
*   **No Ad-hoc Overrides**: Do not implement local configuration files, custom data layers, or other ad-hoc overrides to correct missing or incorrect traffic signs or roads. The official NDW and OSM datasets must remain the authoritative source of truth. Any data discrepancies must be resolved upstream with NDW/OSM rather than via custom workarounds in this codebase.

## 🦄 Coding Philosophy (Ponytail Dev Mode)
AI agents working on this repository MUST adhere to the "lazy senior dev" philosophy defined in [.agents/ponytail.md](file:///home/tomaso/projects/brombrom/.agents/ponytail.md). Key principles:
*   **YAGNI**: Question if a feature needs to be built at all. Prefer deletion over addition, and boring over clever.
*   **No Over-engineering**: Do not introduce unrequested abstractions, boilerplate, or new dependencies if they can be avoided.
*   **Leverage Platform & Stdlib**: Prioritize native platform features and standard library functions before writing custom code.
*   **Quality over Haste**: While code should be minimal, do not compromise on security, input validation, or error handling. Ensure non-trivial logic includes a simple test check.
