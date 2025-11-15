#!/bin/bash

############################################################
#  HDD Fan Curve Controller for Unraid
#  - Dynamic stepped fan curve
#  - Hysteresis
#  - WhatsApp Cloud API alerts
#  - Emergency 100% override
#  - Fully User Scripts compatible
############################################################

#############################
# CONFIGURATION
#############################

# Serial fan controller
PORT="/dev/ttyS0"
BAUD="38400"

# Logging
LOGFILE="/var/log/fan_curve.log"

# WhatsApp Cloud API
WHATSAPP_TOKEN="{PLACEHOLDER_WHATSAPP_TOKEN}"
PHONE_ID="{PLACEHOLDER_PHONE_ID}"
TO_NUMBER="{PLACEHOLDER_TO_NUMBER}"

# Fan limits
MIN_FAN=10
MAX_FAN=50
HYSTERESIS=3

# Temperature → Fan Speed Curve
CURVE=(
    "30:10"
    "34:12"
    "37:15"
    "40:20"
    "43:25"
    "45:30"
    "48:35"
    "52:40"
    "55:50"
)

EMERGENCY_TEMP=55
EMERGENCY_FAN=100


#############################
# LOGGING
#############################
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}


#############################
# WHATSAPP ALERT
#############################
send_whatsapp() {
    local message="$1"

    curl -s -X POST \
      "https://graph.facebook.com/v18.0/$PHONE_ID/messages" \
      -H "Authorization: Bearer $WHATSAPP_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"messaging_product\": \"whatsapp\",
        \"to\": \"$TO_NUMBER\",
        \"type\": \"text\",
        \"text\": { \"body\": \"$message\" }
      }" > /dev/null 2>&1

    log "WhatsApp alert sent: $message"
}


#############################
# INITIALISE SERIAL PORT
#############################
init_serial() {
    if [[ ! -e "$PORT" ]]; then
        log "ERROR: Serial port $PORT not found!"
        return 1
    fi
    stty -F "$PORT" "$BAUD" raw -echo -echoe -echok -echoctl -echoke 2>/dev/null
}


#############################
# SET FAN SPEED
#############################
set_fan() {
    local speed="$1"
    echo -ne "set_speed $speed\r" > "$PORT"
    log "Fan set to $speed%"
}


#############################
# GET DRIVE TEMPERATURES
#############################
get_temps() {
    drive_temps=()

    echo "Detected drive temperatures:"
    echo "----------------------------------"

    while read -r drive; do
        drive=${drive%% *}
        temp=""

        if [[ "$drive" == *"nvme"* ]]; then
            temp=$(smartctl -A -d nvme "$drive" 2>/dev/null | awk '/Temperature:/ {print $2; exit}')
        else
            temp=$(smartctl -A "$drive" 2>/dev/null | awk '
                /Temperature_Celsius/ {print $10; exit}
                /Current\s+Drive\s+Temperature/ {print $4; exit}
                /Drive\s+Temperature/ {print $3; exit}
                /Temperature_Internal/ {print $10; exit}
                /Airflow_Temperature/ {print $10; exit}
                /Temperature:/ {print $2; exit}
            ')
        fi

        if ! [[ "$temp" =~ ^[0-9]+$ ]]; then
            temp=$(smartctl -j -A "$drive" 2>/dev/null | jq -r '.temperature.current // empty')
        fi

        if [[ "$temp" =~ ^[0-9]+$ ]]; then
            drive_temps+=("$temp")
            printf "%-12s : %s°C\n" "$drive" "$temp"
        else
            printf "%-12s : unknown\n" "$drive"
        fi

    done < <(smartctl --scan | awk '{print $1}')

    echo ""
}


#############################
# DETERMINE FAN SPEED FROM CURVE
#############################
calculate_curve_speed() {
    local temp="$1"
    local chosen=$MIN_FAN

    for entry in "${CURVE[@]}"; do
        local threshold=${entry%%:*}
        local speed=${entry##*:}
        (( temp >= threshold )) && chosen="$speed"
    done

    echo "$chosen"
}


#############################
# MAIN LOGIC
#############################

echo ""
echo "=== HDD Dynamic Fan Controller ==="
echo ""

log "Starting evaluation..."

get_temps

############################################################
# FIX: Determine highest drive temperature
############################################################
MAX_TEMP=$(printf "%s\n" "${drive_temps[@]}" | sort -nr | head -1)
log "Highest drive temperature detected: ${MAX_TEMP}°C"


#############################
# HYSTERESIS + CURVE LOGIC
#############################
STATEFILE="/tmp/last_fan_speed"
TEMPFILE="/tmp/last_temp"

LAST_FAN=$(cat "$STATEFILE" 2>/dev/null || echo "$MIN_FAN")
LAST_TEMP=$(cat "$TEMPFILE" 2>/dev/null || echo "$MAX_TEMP")

# Emergency mode
if (( MAX_TEMP >= EMERGENCY_TEMP )); then
    TARGET_FAN=$EMERGENCY_FAN
    log "EMERGENCY MODE: ${MAX_TEMP}°C ≥ ${EMERGENCY_TEMP}°C"
    send_whatsapp "EMERGENCY ALERT: HDD reached ${MAX_TEMP}°C. Fans set to ${EMERGENCY_FAN}% on Unraid!"
else
    TARGET_FAN=$(calculate_curve_speed "$MAX_TEMP")

    if (( TARGET_FAN < LAST_FAN )); then
        if (( MAX_TEMP > LAST_TEMP - HYSTERESIS )); then
            TARGET_FAN=$LAST_FAN
        fi
    fi
fi

echo "$MAX_TEMP" > "$TEMPFILE"
echo "$TARGET_FAN" > "$STATEFILE"


#############################
# APPLY FAN SPEED
#############################

init_serial
set_fan "$TARGET_FAN"

log "Completed. Fan now at $TARGET_FAN%."
echo ""
echo "Fan now running at: $TARGET_FAN%"
echo ""

exit 0
