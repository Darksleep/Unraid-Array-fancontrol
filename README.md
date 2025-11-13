HDD Fan Curve Controller for Unraid

This script is a temperature-based fan controller for Unraid. It reads SMART data from all detected drives, calculates the highest drive temperature, and adjusts fan speed using a stepped fan curve. It supports a serial-controlled fan controller, hysteresis to prevent rapid fan changes, logging, and optional WhatsApp alert notifications.

The WhatsApp alert feature is included but has not been fully tested yet.

Overview

The script checks the temperatures of all drives on the system, including HDDs, SSDs, and NVMe drives. Based on the highest temperature found, it determines an appropriate fan speed using a user-defined temperature/speed curve.

If a drive exceeds a set emergency threshold, the fan is set to 100% and an alert can be sent via WhatsApp (experimental).

The script is compatible with the Unraid User Scripts plugin and can be set to run on a schedule.

Features

Automatic temperature detection using SMART

Stepped fan curve that can be modified by the user

Hysteresis to avoid constant speed changes

Emergency mode at a defined critical temperature

Optional WhatsApp Cloud API alert system (not fully tested)

Logs actions and temperature readings to /var/log/fan_curve.log

Designed for serial-controlled fan systems

Requirements

Unraid

User Scripts plugin

smartctl (included in Unraid)

jq (optional, used for NVMe fallback)

A serial-based fan controller (e.g., Arduino or other fan control hardware)

Installation

Create a new script using the User Scripts plugin.

Paste the script contents into the editor.

Make the script executable:

chmod +x fan_curve.sh


Update the configuration section to match your system (serial port, WhatsApp values, fan curve).

Set the script to run on a schedule (every 5 minutes is typical).

Logging

The script logs important events, detected temperatures, and fan speed changes into:

/var/log/fan_curve.log


This is helpful for troubleshooting or verifying the fan curve logic.

Notes

The WhatsApp alerting system may not work reliably yet. It is included but still experimental, and further testing or improvements may be required.

Make sure your serial fan controller supports the set_speed command or modify the script accordingly.

Use at your own risk. Incorrect fan control could potentially cause overheating if misconfigured.
