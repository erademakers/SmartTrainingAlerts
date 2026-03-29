# SmartTrainingAlerts (Connect IQ v8)

Three **Data Fields**, provided as separate projects:
- **PowerCadenceField** — alerts based on power/cadence conditions.
- **HeartRateField** — alerts based on heart‑rate zone durations.
- **PowerBalance** — turns red when pedal balance falls below a configured threshold.

This project has been **tested with Garmin Connect IQ SDK 8.4.1 on Ubuntu 22.04**, deploying to a **Garmin Edge 1050**.

---

## Development Environment Setup

### Requirements
- Visual Studio Code
- Monkey C Extension (Garmin)
- Garmin Connect IQ SDK **8.4.1**
- At least one device installed in SDK Manager (e.g., Edge 1050)

### Install
1. Install the **Garmin Connect IQ SDK Manager**:  <https://developer.garmin.com/connect-iq/sdk/>
2. Use SDK Manager to install:
   - SDK 8.4.1
   - Edge 1050 device profile
3. Install Visual Studio Code
4. Install the **Monkey C** extension (Garmin)
5. Run:
   ```
   Ctrl + Shift + P → Monkey C: Verify Installation
   ```

---

## Project Structure
Each datafield is a separate project:

```
PowerCadence/
HeartRate/
PowerBalance/
```

Each project contains:
- `manifest.xml` — schema v3, validated
- `monkey.jungle`
- `build_iq.sh` — builds a release `.iq` package for portal/beta upload
- `source/` — your Monkey C code
- `resources/` — icons, strings, settings

---

## Build the Project
In Visual Studio Code:

```
Ctrl + Shift + B
```

Or:
```
Ctrl + Shift + P → Monkey C: Build for Device
```

A `.prg` file will be created in:
```
bin/
```

---

## Test in Simulator (Run and Debug)
Use VS Code + Connect IQ Simulator to test quickly without deploying to a physical device.

1. Open **Run and Debug** in VS Code.
2. Choose the correct project configuration:
   - `Debug PowerCadence (edge1050)`
   - `Debug HeartRate (edge1050)`
   - `Debug PowerBalance (edge1050)`
3. Press **Run and Debug**.
4. In the simulator, load activity data:
   - Use FIT playback (FIT file) for realistic ride data.
   - You can also change simulated sensor/activity values to test thresholds and alerts.
5. Verify field behavior (colors, thresholds, alerts) before creating a release package.

---

## Deploy for Own Use (Sideloading)

> ⚠️ **macOS only**: macOS does not mount the Edge as a normal USB drive.  
> Install **Android File Transfer**: <https://www.android.com/filetransfer/>

1. Build the project to get a `.prg` in `bin/`.
2. Connect the Edge 1050 via USB.
3. Open Android File Transfer.
4. Go to:
   ```
   GARMIN/Apps/
   ```
5. Copy the `.prg` file into that folder.
6. Disconnect and restart the device.

---

## Configure Settings
Settings are defined in:
```
resources/settings/settings.xml
```

Settings can be changed only through the **Connect IQ mobile app** when the app is installed via beta/store flow.

Sideloaded `.prg` installs do not provide an editable settings screen.

Path in the Connect IQ app:
```
My Device → Activities & Apps → Data Fields → [App] → Settings
```

---

## Beta Install via iPhone + Connect IQ App (Build + Upload + Install)

Use this flow when you want proper app settings support and reliable install/update behavior.

### 1. Build `.iq` package (no `.prg` build required)

Each project root contains a `build_iq.sh` script that builds the signed release `.iq` package.

Use your existing signing key:
```
/Users/erwinrademakers/MonkeyC/developer_key
```

Build per project:

**HeartRate**
```bash
cd /Users/erwinrademakers/workspace/SmartTrainingAlerts/HeartRate
bash build_iq.sh
```

**PowerCadence**
```bash
cd /Users/erwinrademakers/workspace/SmartTrainingAlerts/PowerCadence
bash build_iq.sh
```

**PowerBalance**
```bash
cd /Users/erwinrademakers/workspace/SmartTrainingAlerts/PowerBalance
bash build_iq.sh
```

### 2. Upload in Garmin Developer Portal
1. Open [apps.garmin.com/developer/dashboard](https://apps.garmin.com/developer/dashboard)
2. Open your app (or create one)
3. Go to **Beta Testing**
4. Upload the generated `.iq` file
5. Click **Publish Beta**

### 3. Install on iPhone/Edge
1. Open the beta install link on your iPhone
2. Open in **Connect IQ**
3. Choose your Edge 1050
4. Sync Garmin Connect
5. Verify field on device under data fields

Troubleshooting:
- Remove old sideloaded `.prg` of the same app before beta install.
- If install fails, republish beta and use the newest beta link.

---

## Screenshots
Place images in an `/images` folder and reference them like:
```markdown
![Build](images/build.png)
![Settings](images/settings.png)
![SmartCadence](images/smartcadence.png)
![SmartHeartRate](images/smartheartrate.png)
```

---
