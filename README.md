# HDD Fan Curve Controller (Unraid & Linux)

A simple fan-control script for systems that use a serial-controlled fan board, such as Dell MD1200/MD1220 shelves or JBOD enclosures without built-in fan logic.  
The script reads drive temperatures via SMART and adjusts fan speed using a stepped temperature curve.

---

## Supported Hardware

- Dell MD1200 / MD1220
- JBOD shelves with serial fan controllers
- Any Linux server with a serial-connected fan board

---

## Requirements

- bash
- smartctl
- jq
- Serial fan controller (e.g. /dev/ttyS0 or /dev/ttyUSB0)

---

## What the Script Does

- Reads temperatures from HDD/SSD/NVMe drives
- Uses the highest drive temperature for control
- Applies a stepped fan curve
- Includes hysteresis to prevent rapid speed changes
- Emergency override (forces 100% fan)
- Logs all fan changes
- Optional WhatsApp temperature alerts

---

## Default Fan Curve

| Temperature | Fan Speed |
|-------------|-----------|
| 30°C | 10% |
| 34°C | 12% |
| 37°C | 15% |
| 40°C | 20% |
| 43°C | 25% |
| 45°C | 30% |
| 48°C | 35% |
| 52°C | 40% |
| 55°C | 50% |

**Emergency Mode:** At 55°C and above, fan speed is forced to 100%.

---

## Why This Exists

Dell MD1200/MD1220 shelves only control fan speed when used with a Dell RAID controller.  
When connected to an IT-mode HBA, they run at full speed constantly.  
By installing a small serial-controlled fan board inside the shelf, this script provides automatic cooling control.

---

## Installation (Unraid)

1. Install the **User Scripts** plugin.
2. Create a new script and paste the full script.
3. Edit the configuration section at the top.
4. Run it manually once to verify it works.
5. Schedule it to run every minute.

---

## Installation (Linux)

```bash
sudo apt install smartmontools jq
chmod +x fan_curve.sh
./fan_curve.sh
```

---

```Cronjob
* * * * * /path/to/fan_curve.sh
```

---
These shelves do not perform fan regulation when connected to a non-Dell HBA.
This script restores automatic control using a serial fan controller.

---Disclaimer
Use at your own risk. Confirm your serial controller responds properly before relying on it for thermal management.****

