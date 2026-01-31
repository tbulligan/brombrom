# Manual Installation Guide (Advanced / iOS)

> [!IMPORTANT]
> **Prerequisite**: Ensure **OsmAnd** is installed before proceeding.

## 🆕 First-Time Installation
1.  **Download** the following from the **[latest release](https://github.com/tbulligan/brombrom/releases/latest)**:
    *   `routing.xml`
    *   `NL_BromBrom_tagged.obf`
2.  **Transfer** them to your phone. 
3.  **Create Profile**:
    *   In OsmAnd: **Settings** -> **App Profiles** -> **New Profile**.
    *   Base it on **Driving**. Name it **BromBrom**. Tap **Apply**.
4.  **Import Routing**:
    *   Select your new **BromBrom** profile.
    *   Go to **Navigation Settings** -> **Navigation Type**.
    *   Tap **Import routing file** and select the `routing.xml` you transferred.
5.  **Install Map**:
    *   Locate `NL_BromBrom_tagged.obf` in your file manager and choose **"Open with OsmAnd"**.

## 🔄 Monthly Update (Manual)
1.  **Download** the new `NL_BromBrom_tagged.obf`.
2.  **Delete Old Map**: In OsmAnd: **Settings** -> **Maps & Resources** -> **Local** -> **Standard maps** -> Delete `NL_BromBrom_tagged`.
3.  **Install New Map**: Open the new `.obf` with OsmAnd.

## 🍎 iOS Support (Manual Transfer)

> [!NOTE]
> iOS support is Experimental. The iOS version of OsmAnd lacks the "Import routing file" button.

1.  **Transfer** files to your iPhone (AirDrop or iCloud).
2.  **Install Map**: Tap `NL_BromBrom_tagged.obf` -> Share -> **OsmAnd**.
3.  **Install Routing**:
    *   Open the iOS **Files** app.
    *   **Move** `routing.xml` to: `On My iPhone` -> `OsmAnd` -> `AppData` -> `routing` (create the `routing` folder if it is missing).
4.  **Configure Profile**:
    *   **Settings** -> **App Profiles** -> **New Profile** (Base on **Driving**, name it **BromBrom**).
    *   **Navigation Settings** -> **Navigation Type** -> Select **BromBrom**.
