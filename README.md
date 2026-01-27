# BromBrom: Microcar Navigation for Android

**BromBrom** creates a professional-grade offline navigation package for L6e microcars (Brommobielen) in the Netherlands. It solves the unique routing challenges of microcars by rigorously excluding forbidden roads (C9 signs, motorways) using official NDW traffic data and OpenStreetMap.

## Features

- **Advanced Routing Engine**: Generates a custom `.obf` map for OsmAnd with "C9-forbidden" tags baked into the road network.
- **Intelligent Restriction Logic**: Specifically handles Dutch C9 traffic signs by verifying supplementary plates; roads with `OB65` (microcar exception) remain accessible, while standard C9 roads are strictly excluded.
- **End-to-End Docker Pipeline**: One command fetches data, processes geometry, snaps traffic signs, and builds Android artifacts.
- **Zero-Touch Deployment**: Outputs a single `brombrom_android_deploy.zip` ready for your phone.

## Routing Engine

The primary navigation experience is designed for **OsmAnd**. By baking the restrictions directly into the map data, you get full turn-by-turn guidance, lane assistance, and street names while safely avoiding forbidden roads.

### Optional: BRouter (Developer/Backup)
BRouter is supported as an optional, secondary routing engine. It uses a rule-based engine (`.brf`) and can be useful for developer auditing or as a fallback. 
*To include BRouter segments in your build, see the "Advanced Build" section below.*

## How it Works (Under the Hood)

BromBrom doesn't just "prefer" certain roads; it programmatically enforces legal restrictions:

1.  **Data Fusion**: We combine the latest **OpenStreetMap** road network with the **NDW (National Data Portal)** live traffic sign database.
2.  **Spatial Analysis**: Every C9 traffic sign is snapped to the nearest road segment using directional logic (matching sign orientation to road bearing).
3.  **Heuristic Filtering**: Signs with `OB65` (microcar exception) text are discarded, while remaining forbidden segments are flagged.
4.  **Semantic Tagging**: The pipeline modifies the raw OSM data, injecting `motor_vehicle=no` and `microcar=no` tags into the forbidden segments.
5.  **Hard Blocking**: Because these tags are baked into the `.obf` map, the routing engine treats these roads as physically inaccessible for your vehicle type.

## Safety & Resilience (What if I get lost?)

If you mistakenly enter a forbidden road (e.g., following traffic or missing a sign), BromBrom is designed to recover gracefully:

- **GPS Snapping**: Even if you are physically on a restricted road, the navigation app will try to "snap" your position to the nearest **legal** road.
- **Beeline Recovery**: If you are too far from a legal road, OsmAnd will show a straight "beeline" to the nearest legal point. Once you cross back onto a permitted street, turn-by-turn guidance resumes automatically.
- **The "Legal Anchor"**: The map will never suggest a U-turn or a shortcut onto a C9 road. You remain the pilot; always prioritize immediate safety and physical traffic signs.

## Getting Started

### Prerequisites
- Docker (with BuildKit support)

### Build the Map
1. **Clone the repository**:
   ```bash
   git clone https://github.com/tbulligan/brombrom.git
   cd brombrom
   ```

2. **Build the Docker Image**:
   ```bash
   docker buildx build -t brombrom-builder .
   ```

3. **Run the Pipeline**:
   ```bash
   docker run --rm -v $(pwd):/app brombrom-builder
   ```
   *Note: The first run downloads ~1.5GB of map data. Subsequent runs use local cache.*

4. **Get the Artifact**:
   Find `brombrom_android_deploy.zip` in the `dist/` folder.

## Installation on Android

1. Connect your phone to your PC.
2. Unzip `brombrom_android_deploy.zip` to the **root** of your internal storage.
3. **Setup OsmAnd**:
   - Settings -> Select Profile -> Navigation Settings -> Navigation Type -> Select **`routing.xml`** (might appear as 'microcar') as the style.

## Advanced: Including BRouter (Optional)

If you require BRouter as a secondary backup or for auditing purposes:

1. **Build with BRouter segments**:
   ```bash
   docker run --rm -v $(pwd):/app -e INCLUDE_BROUTER=true brombrom-builder
   ```
2. **Setup BRouter on Android**:
   - After unzipping the package, open the BRouter app.
   - Select the `brommobiel` profile.
   - Set to **Server-Mode** -> OK -> Exit.
   - In OsmAnd, you can then switch the "Routing Service" to BRouter in your profile settings.

## Performance & Build Notes

- **Stage 1 & 2 (Downloads)**: The initial build downloads ~1.5GB of geospatial data. Ensure you have a stable connection.
- **Stage 2 (OsmAnd OBF Generation)**: This is the most resource-intensive part of the pipeline.
  - **Memory**: It is configured to use up to 10GB of RAM.
  - **Duration**: Depending on your hardware, this can take 20-40 minutes.
  - **Progress Feedback**: The OsmAnd IndexBatchCreator often reports progress percentages exceeding 100% (e.g., `Done 450%`). This is normal behavior as it processes multiple data layers (Routing, POI, Address) sequentially.
- **Idempotency**: The pipeline skips already completed stages. Run `./clean.sh` if you want to force a fresh build from scratch.

## Project Structure

- `scripts/`: Python processing pipelines (Data fetching, Snapping, Tagging).
- `config/`: Routing profiles (`.brf`) and XML configurations.
- `Dockerfile`: Multi-stage Docker build environment.

## License & Legal

### Data Attributions
- **Map Data**: © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright) (ODbL).
- **Traffic Sign Data**: Provided by [NDW](https://www.ndw.nu/) (National Data Portal for Road Traffic).

### Project License
© 2026 Tomaso Bulligan. All Rights Reserved.

**Current Status**: This project is provided for personal, non-commercial use only. Redistribution, commercial use, or inclusion in paid products is strictly prohibited without prior written consent.