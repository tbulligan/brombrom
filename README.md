# BromBrom: OsmAnd Microcar Navigation (Netherlands)

**BromBrom** creates a professional-grade **OsmAnd** navigation package specifically for L6e microcars (*Brommobielen*) in the Netherlands. It solves the unique routing challenges of microcars by rigorously excluding forbidden roads (C9 signs, motorways) from the map data using official NDW traffic data and OpenStreetMap.

## Features

- **Advanced Routing Engine**: Generates a custom `.obf` map for OsmAnd with "C9-forbidden" tags baked into the road network.
- **Intelligent Restriction Logic**: Specifically handles Dutch C9 traffic signs by verifying supplementary plates; roads with `OB65` (microcar exception) remain accessible.
- **End-to-End Docker Pipeline**: One command fetches data, processes geometry, snaps traffic signs, and builds Android artifacts.
- **Zero-Touch Deployment**: Outputs a single `brombrom_android_deploy.zip` ready for your phone.

---

## 🚀 Getting Started

### Prerequisites
- **Docker**: with BuildKit support.
- **OsmAnd (Android App)**: **Required** for using the generated maps. (Available on Play Store/F-Droid).
- **System Memory**: At least **6GB RAM** is required for the map generation stage.

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

### 2. Installation on Android (OsmAnd)
1. Connect your phone to your PC.
2. Unzip `brombrom_android_deploy.zip` to the **root** of your internal storage.
3. **Setup OsmAnd**:
   - Open OsmAnd -> Settings -> Profiles -> [Select Profile] -> Navigation settings -> Route parameters -> **Navigation type**.
   - Select **`routing.xml`** (may appear as *microcar*).
> **Note**: BromBrom generates a custom `.obf` map file. Once it's in the correct OsmAnd folder, it will be automatically detected and used for routing.

### 🍏 Experimental: iOS Support
The generated `.obf` and `routing.xml` files are cross-platform and theoretically work on **OsmAnd for iOS**. However, because iOS lacks the direct file structure of Android, you must manually import the files:
- Transfer the `.obf` and `routing.xml` files from the zip to your iPhone (via AirDrop, iCloud, or Files app).
- Open them with the OsmAnd app to import.
- Note: This path is currently manual and experimental.

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
- **Legal Safety**: The app will never plan a route through a C9 road or use one as a shortcut. If you accidentally end up on a restricted road, the app will immediately guide you to the nearest legal exit. **Crucially: Digital maps can have errors; if you see a physical C9 sign, always obey the sign over the app.**

---

## � Primary Navigation: OsmAnd

OsmAnd is the **required** primary experience for BromBrom. By baking the C9 and motorway restrictions directly into the `.obf` map data, OsmAnd provides:
- **Full Voice Guidance**: Street names and turn instructions.
- **Lane Assistance**: Visual indicators for complex intersections.
- **Offline Reliability**: 100% offline navigation without data usage.

---

## 🛠️ Optional: BRouter (Developer / Backup)

While OsmAnd is the primary engine, BRouter is supported as an **optional** secondary fallback or for technical auditing. 
Specify the environment variable to generate BRouter segments:
```bash
docker run --rm -v $(pwd):/app -e INCLUDE_BROUTER=true brombrom-builder
```
**Setup**: Open the BRouter app -> Select `brommobiel` profile -> Set to **Server-Mode**.

---

## 📈 Performance & Build Notes

- **Initial Build**: Downloads ~1.5GB of geospatial data. Ensure a stable connection.
- **OsmAnd OBF Generation**: This is the most resource-intensive part.
  - **Memory**: It is configured to use up to **6GB** of RAM (compatible with GitHub free runners).
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
- **Traffic signs**: Provided by [NDW](https://www.ndw.nu/) (Nationaal Dataportaal Wegverkeer).

### Project License
© 2026 Tomaso Bulligan. All Rights Reserved.
**Personal, non-commercial use only.** Redistribution or commercial exploitation is strictly prohibited without prior written consent.