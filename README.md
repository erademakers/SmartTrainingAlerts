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

### ✔ Method 2 — Manual Install (USB Copy)
1. Build the project → get `.prg` from `bin/`
2. Connect the Edge via USB
3. Copy the `.prg` file into:
   ```
   GARMIN/APPS/
   ```
4. Disconnect and restart the device

---

## ⚙ Configure Settings (Edge UI or Connect IQ App)
Settings are defined in:
```
resources/settings/settings.xml
```

You can edit settings:

### ✔ On the Edge 1050 (on‑device settings)
```
Activity Profile → Data Fields → Connect IQ → SmartTrainingAlerts_* → Settings
```

### ✔ Using the Connect IQ mobile app
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
