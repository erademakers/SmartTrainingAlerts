# SmartTrainingAlerts (Connect IQ v8)

Three **Data Fields**, provided as separate projects:
- **PowerCadenceField** — alerts based on power/cadence conditions.
- **HeartRateField** — alerts based on heart-rate zone durations.
- **PowerBalance** — turns red when pedal balance falls below a configured threshold.

Tested with Garmin Connect IQ SDK 8.4.1, deploying to a **Garmin Edge 1050**.

---

## Development Environment Setup

### Requirements
- Visual Studio Code
- Monkey C Extension (Garmin)
- Garmin Connect IQ SDK **8.4.1**
- At least one device installed in SDK Manager (e.g., Edge 1050)

### Install
1. Install the **Garmin Connect IQ SDK Manager**: <https://developer.garmin.com/connect-iq/sdk/>
2. Use SDK Manager to install:
   - SDK 8.4.1
   - Edge 1050 device profile
3. Install Visual Studio Code
4. Install the **Monkey C** extension (Garmin)
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
- `monkey.jungle` — release build
- `monkey.debug.jungle` — simulator/debug build
- `source/` — shared app code
- `source-debug/BuildConfig.mc` — build flags for simulator
- `source-release/BuildConfig.mc` — build flags for release
- `resources/` — icons, strings, settings

---

## Build Configuration

Build flags are separated from source code and selected automatically based on the jungle file used.

| Build | Jungle file | Config loaded |
|---|---|---|
| Simulator / Run & Debug (F5) | `monkey.debug.jungle` | `source-debug/BuildConfig.mc` |
| Connect IQ task / `build_iq.sh` | `monkey.jungle` | `source-release/BuildConfig.mc` |

To change test behavior, only edit `source-debug/BuildConfig.mc` — the release config is never touched during development.

### HeartRate — `source-debug/BuildConfig.mc` (simulator)
```monkeyc
const DEBUG_MODE                     = true;
const TEST_SYNTHETIC_HR              = true;
const TEST_TIME_SCALE                = 1.0;
const TEST_MAX_HR                    = 190;
const TEST_CURRENT_INTERVAL_OVERRIDE = false;
const TEST_CURRENT_Z4_INTERVAL       = 120.0;
const TEST_CURRENT_Z5_INTERVAL       = 30.0;
```

### HeartRate — `source-release/BuildConfig.mc` (release)
```monkeyc
const DEBUG_MODE                     = false;
const TEST_SYNTHETIC_HR              = false;
```

---

## VS Code Tasks

Each project has VS Code tasks configured in `.vscode/tasks.json`.

Run via:
```
Cmd + Shift + P → Tasks: Run Task
```

| Project | Task | Output | Purpose |
|---|---|---|---|
| HeartRate | `Build HeartRate` | `bin/HeartRate.prg` | Simulator / debug |
| HeartRate | `Build HeartRate (Connect IQ)` | `bin/HeartRate.iq` | Release / portal upload |
| PowerCadence | `Build PowerCadence` | `bin/PowerCadence.prg` | Simulator / debug |
| PowerCadence | `Build PowerCadence (Connect IQ)` | `bin/PowerCadence.iq` | Release / portal upload |
| PowerBalance | `Build PowerBalance` | `bin/PowerBalance.prg` | Simulator / debug |
| PowerBalance | `Build PowerBalance (Connect IQ)` | `bin/PowerBalance.iq` | Release / portal upload |

The **simulator build** (`Build <Project>`) runs automatically on **Run and Debug (F5)** via `preLaunchTask` in `.vscode/launch.json`.

The **Connect IQ build** (`Build <Project> (Connect IQ)`) produces a signed `.iq` package — equivalent to `bash build_iq.sh`.

---

## Test in Simulator (Run and Debug)

1. Open **Run and Debug** in VS Code.
2. Choose the configuration for the project you want to test:
   - `Debug HeartRate (edge1050)`
   - `Debug PowerCadence (edge1050)`
   - `Debug PowerBalance (edge1050)`
3. Press **F5** — the project is built automatically before the simulator launches.
4. Load activity data in the simulator:
   - Use FIT playback for realistic ride data.
   - Or manually set sensor values to trigger thresholds and alerts.
5. Adjust app settings without redeploying:
   ```
   File → Edit Persistent Storage → Edit application.properties Data
   ```
6. Debug output is visible in the **Connect IQ** tab in the VS Code terminal.

---

## HeartRate: Testing with Synthetic Data

The HeartRate field has a built-in synthetic HR mode that drives HR from a hardcoded time sequence, without requiring a FIT file or physical sensor (FIT files do not supply usable HR data in the simulator).

Enable by setting in `source-debug/BuildConfig.mc`:
```monkeyc
const TEST_SYNTHETIC_HR = true;
```

### Adjusting the HR sequence

Edit `getSyntheticHr()` in `HeartRateView.mc`:

```monkeyc
var seq = [
    [10,  125],   // 10s in Z2 (warmup)
    [30,  185],   // 30s in Z5 (spike)
    [30,  120],   // 30s in Z2 (recovery)
    [10,  185],   // 10s in Z5 (spike)
    [120, 110],   // 120s in Z1 (cooldown)
];
```

Each entry is `[duration_in_seconds, heart_rate]`. The sequence loops automatically.

### Time acceleration

```monkeyc
const TEST_TIME_SCALE = 10.0;  // 10x faster — 30s in Z5 takes 3s real-time
```

### Pre-filling the interval timer (optional)

To test alert behavior when already partway through a zone interval:

```monkeyc
const TEST_CURRENT_INTERVAL_OVERRIDE = true;
const TEST_CURRENT_Z4_INTERVAL = 120.0;   // simulate 2 min already in Z4
const TEST_CURRENT_Z5_INTERVAL = 30.0;    // simulate 30s already in Z5
```

---

## Configure App Settings

Settings are defined in `resources/settings/settings.xml` and can be changed:

- **In the simulator**: `File → Edit Persistent Storage → Edit application.properties Data`
- **On device**: through the Connect IQ mobile app (only when installed via beta/store flow)

Path in the Connect IQ app:
```
My Device → Activities & Apps → Data Fields → [App] → Settings
```

Sideloaded `.prg` installs do not provide an editable settings screen.

---

## Deploy for Own Use (Sideloading)

> ⚠️ **macOS only**: macOS does not mount the Edge as a normal USB drive.
> Install **Android File Transfer**: <https://www.android.com/filetransfer/>

1. Run the simulator build task to get a `.prg` in `bin/`.
2. Connect the Edge 1050 via USB.
3. Open Android File Transfer.
4. Copy the `.prg` file to `GARMIN/Apps/`.
5. Disconnect and restart the device.

---

## Beta Install via iPhone + Connect IQ App

Use this flow when you need proper settings support and reliable install/update behavior.

### 1. Build `.iq` package

**Option A — VS Code task (recommended):**
```
Cmd + Shift + P → Tasks: Run Task → Build <Project> (Connect IQ)
```

**Option B — terminal:**
```bash
cd HeartRate && bash build_iq.sh
cd PowerCadence && bash build_iq.sh
cd PowerBalance && bash build_iq.sh
```

The `.iq` file is written to `bin/`.

### 2. Upload to Garmin Developer Portal
1. Open [apps.garmin.com/developer/dashboard](https://apps.garmin.com/developer/dashboard)
2. Open your app → **Beta Testing**
3. Upload the `.iq` file and click **Publish Beta**

### 3. Install on device
1. Open the beta install link on your iPhone
2. Open in **Connect IQ** and choose your Edge 1050
3. Sync Garmin Connect
4. Verify the field appears under data fields on the device

**Troubleshooting:**
- Remove any sideloaded `.prg` of the same app before beta install.
- If install fails, republish beta and use the newest beta link.

---

## Screenshots
Place images in an `/images` folder and reference them like:
```markdown
![SmartCadence](images/smartcadence.png)
![SmartHeartRate](images/smartheartrate.png)
```

---
