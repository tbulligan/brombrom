# BromBrom: Microcar Navigation for Android

**BromBrom** creates a professional-grade offline navigation package for L6e microcars (*Brommobielen*) in the Netherlands. It solves the unique routing challenges of microcars by rigorously excluding forbidden roads (C9 signs, motorways) using official NDW traffic data and OpenStreetMap.

## Features

- **Advanced Routing Engine**: Generates a custom `.obf` map for OsmAnd with "C9-forbidden" tags baked into the road network.
- **Intelligent Restriction Logic**: Specifically handles Dutch C9 traffic signs by verifying supplementary plates; roads with `OB65` (microcar exception) remain accessible.
- **End-to-End Docker Pipeline**: One command fetches data, processes geometry, snaps traffic signs, and builds Android artifacts.
- **Zero-Touch Deployment**: Outputs a single `brombrom_android_deploy.zip` ready for your phone.

---

## 🚀 Getting Started

### Prerequisites
- **Docker**: with BuildKit support.
- **System Memory**: At least **10GB RAM** is required for the map generation stage.

### 1. Build the Map
```bash
# Clone and enter the repo
git clone https://github.com/tbulligan/brombrom.git
cd brombrom

# Build the builder image
docker buildx build -t brombrom-builder .

# Run the pipeline (downloads ~1.5GB data on first run)
docker run --rm -v $(pwd):/app brombrom-builder
```
Find your artifact `brombrom_android_deploy.zip` in the `dist/` folder.

### 2. Installation on Android
1. Connect your phone to your PC.
2. Unzip `brombrom_android_deploy.zip` to the **root** of your internal storage.
3. **Setup OsmAnd**:
   - Settings -> Select Profile -> Navigation Settings -> Navigation Type -> Select **`routing.xml`** (may appear as 'microcar').

---

## 🧠 How it Works & Safety

### Under the Hood
BromBrom doesn't just "prefer" certain roads; it programmatically enforces legal restrictions:
1. **Data Fusion**: Combines latest **OpenStreetMap** data with the **NDW** live traffic sign database.
2. **Directional Snapping**: Signs are snapped to roads using orientation logic to ensure the correct side of the road is blocked.
3. **Semantic Tagging**: Injects `motor_vehicle=no` and `microcar=no` tags directly into the road network.
4. **Hard Blocking**: The routing engine treats these roads as physically inaccessible for your vehicle type.

### Safety & Resilience (What if I get lost?)
If you mistakenly enter a forbidden road (e.g., following traffic or missing a sign):
- **GPS Snapping**: The app will try to "snap" your position to the nearest **legal** road on the map.
- **Beeline Recovery**: If you are too far from a legal road, OsmAnd shows a "beeline" to the nearest exit point. guidance resumes once you reach a permitted street.
- **Pilot Responsibility**: The map will never suggest a U-turn or shortcut onto a C9 road, but you must always obey physical signs in the real world.

---

## 🛠️ Routing Engines

| Feature | OsmAnd (Native) | BRouter (External) |
| :--- | :--- | :--- |
| **Primary Use** | **Recommended (Daily Driver)** | **Backup (Safety Audit)** |
| **Guidance** | Rich: Street names, lanes, voice. | Basic: Turn symbols and distance only. |
| **Recovery** | Excellent "Rescue" beeline logic. | Sensitive; may fail if too far off-road. |
| **Stability** | Fully integrated UI experience. | Extremely robust offline fallback. |

### Advanced: Including BRouter (Optional)
Specify the environment variable to generate BRouter segments:
```bash
docker run --rm -v $(pwd):/app -e INCLUDE_BROUTER=true brombrom-builder
```
**Setup**: Open the BRouter app -> Select `brommobiel` profile -> Set to **Server-Mode**.

---

## 📈 Performance & Build Notes

- **Initial Build**: Downloads ~1.5GB of geospatial data. Ensure a stable connection.
- **OsmAnd OBF Generation**: This is the most resource-intensive part.
  - **Duration**: 20-40 minutes depending on hardware.
  - **Feedback**: Progress over 100% (e.g., `Done 450%`) is normal as it cycles through data layers.
- **Idempotency**: The pipeline skips finished stages. Run `./clean.sh` for a fresh start.

---

## 📂 Project Structure
- `scripts/`: Python ETL pipelines (Fetching, Snapping, Tagging).
- `config/`: Routing profiles (`.brf`) and XML configurations.
- `Dockerfile`: Multi-stage build environment.

---

## ⚖️ License & Legal

### Data Attributions
- **Map Data**: © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright) (ODbL).
- **Traffic signs**: Provided by [NDW](https://www.ndw.nu/) (National Data Portal).

### Project License
© 2026 Tomaso Bulligan. All Rights Reserved.
**Personal, non-commercial use only.** Redistribution or commercial exploitation is strictly prohibited without prior written consent.