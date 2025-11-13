# HDD Fan Curve Controller for Unraid

This script provides a temperature-based fan controller for Unraid. It reads SMART data from all connected drives, determines the hottest drive, and adjusts the fan speed based on a stepped fan curve. It also includes optional WhatsApp Cloud API alerts for high temperatures. The WhatsApp alert feature is included but not fully tested yet.

The script is designed to work with a serial-controlled fan system and integrates cleanly with the Unraid User Scripts plugin.

---

## Features

- Reads temperatures from HDDs, SSDs, and NVMe drives using SMART  
- Stepped fan curve that can be customised  
- Hysteresis system to prevent constant fan speed fluctuations  
- Emergency mode that forces fan speed to 100% at a defined temperature  
- Optional WhatsApp alert support (experimental)  
- Logs temperature readings and fan adjustments to `/var/log/fan_curve.log`  
- Works with serial-based fan controllers

---

## How It Works

1. The script scans for all detectable drives using `smartctl`.
2. It extracts the temperature using multiple fallbacks to support different drive types.
3. It identifies the highest drive temperature.
4. It selects the correct fan speed based on the configured fan curve.
5. Hysteresis logic prevents the fan from ramping down too quickly.
6. If the emergency temperature is reached, the fan is set to 100%.
7. If WhatsApp alerts are enabled, an alert message can be sent.

---

## Requirements

- Unraid  
- User Scripts plugin  
- `smartctl` (included with Unraid)  
- `jq` (recommended for NVMe fallback parsing)  
- Serial fan controller hardware (e.g., Arduino or similar)

---

## Installation

1. Open the User Scripts plugin in Unraid.
2. Create a new script and paste the contents of the file.
3. Make the script executable:

   ```bash
   chmod +x fan_curve.sh

