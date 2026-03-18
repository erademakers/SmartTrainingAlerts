# SmartTrainingAlerts (Connect IQ v8)

Two **Data Fields**, provided as separate projects:
- **PowerCadenceField** — alerts based on power/cadence conditions.
- **HeartRateField** — alerts based on heart‑rate zone durations.

This project has been **tested with Garmin Connect IQ SDK 8.4.1 on Ubuntu 22.04**, deploying to a **Garmin Edge 1050**.

---

## 🔧 Development Environment Setup

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

## 📂 Project Structure
Each datafield is a separate project:

```
SmartTrainingAlerts_PowerCadence/
SmartTrainingAlerts_HeartRate/
```

Each project contains:
- `manifest.xml` — schema v3, validated
- `monkey.jungle`
- `source/` — your Monkey C code
- `resources/` — icons, strings, settings

---

## 🛠 Build the Project
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

## 🚀 Deploy to Your Garmin Device (Edge 1050)
There are **two supported deployment methods**:

### ✔ Method 1 — Deploy Directly from VS Code (recommended)
1. Connect your Garmin Edge 1050 via USB
2. In VS Code:
   ```
   Ctrl + Shift + P → Monkey C: Build for Device
   ```
3. Select the **Edge 1050**
4. VS Code automatically copies the `.prg` into:
   ```
   GARMIN/APPS/
   ```
5. Disconnect and restart the device
6. Add the Data Field under:
   ```
   Activity Profile → Data Screens → Connect IQ Fields
   ```

### ✔ Method 2 — Manual Install via USB (Sideloading)

> ⚠️ **macOS only**: macOS does not support the Garmin Edge as a USB drive natively.  
> You need to install **Android File Transfer**: <https://www.android.com/filetransfer/>

1. Install **Android File Transfer** on your Mac (see link above)
2. Build the project → get `.prg` from `bin/`
3. Connect the Edge 1050 via USB
4. Open **Android File Transfer** — it shows the Garmin file system
5. Navigate to:
   ```
   GARMIN/Apps/
   ```
6. Drag and drop your `.prg` file into that folder
7. Disconnect and restart the device

> ⚠️ **Settings not available with sideloading** — see the [Configure Settings](#️-configure-settings-edge-ui-or-connect-iq-app) section below.

---

## ⚙ Configure Settings (Edge UI or Connect IQ App)
Settings are defined in:
```
resources/settings/settings.xml
```

> ⚠️ **Important: Sideloaded apps (.prg) do NOT support settings**
>
> If you install the app by manually copying a `.prg` file to `GARMIN/APPS/`, the settings screen will **not** appear in Garmin Connect or on the Edge itself.  
> Settings only work when the app is installed via the **Connect IQ developer portal** (even as a private beta).

---

### ✅ Recommended: Upload as Beta via Developer Portal

To get full settings support, upload your app as a private beta:

1. Go to [apps.garmin.com/developer](https://apps.garmin.com/developer) and log in
2. Click **Create an App**, fill in name and category (**Data Field**), add Edge 1050 as supported device
3. Build a `.iq` package from the command line:
   ```
   monkeyc -o bin/HeartRate.iq -f monkey.jungle -y /path/to/developer_key.der -d edge1050 -r
   ```
4. Upload the `.iq` file in the portal under **Beta Testing**
5. Click **Publish Beta** — you receive a private install link
6. Open the link on your phone → **Send to device** → sync your Edge
7. Settings are now available via Garmin Connect app:

```
My Device → Connect IQ Apps → HeartRate / PowerCadence → Settings
```

---

### ✔ On the Edge 1050 (on‑device settings, only when installed via portal)
```
Activity Profile → Data Fields → Connect IQ → SmartTrainingAlerts_* → Settings
```

### ✔ Using the Connect IQ mobile app (only when installed via portal)
```
My Device → Activities & Apps → Data Fields → SmartTrainingAlerts_* → Settings
```

---

## 📸 Screenshots
Place images in an `/images` folder and reference them like:
```markdown
![Build](images/build.png)
![Settings](images/settings.png)
```

---
