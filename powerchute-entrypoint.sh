#!/bin/sh
set -e

echo "=== APC PowerChute Serial Shutdown Agent ==="

# Install RPM on first run if provided
if [ -f /tmp/pcssagent.rpm ] && [ ! -d /opt/APC/PowerChuteSerialShutdown/Agent ]; then
    echo "Installing PowerChute RPM..."
    /tmp/install-powerchute.sh
fi

# Check if PowerChute is installed
if [ ! -d /opt/APC/PowerChuteSerialShutdown/Agent ]; then
    echo "ERROR: PowerChute not installed!"
    echo ""
    echo "Please provide the PowerChute RPM file by mounting it:"
    echo "  docker run -v /path/to/pcssagent-*.x86_64.rpm:/tmp/pcssagent.rpm ..."
    echo ""
    echo "Or extract it first and mount the directory:"
    echo "  docker run -v ./pcssagent:/tmp/pcssagent ..."
    exit 1
fi

cd /opt/APC/PowerChuteSerialShutdown/Agent

# Apply configuration from environment variables if config.ini doesn't exist or is forced
if [ ! -f config.ini ] || [ "$RECONFIGURE" = "true" ]; then
    echo "Configuring PowerChute..."

    # Create configuration from environment variables
    cat > config.ini << EOF
[PowerChute]
UPS_Manufacturer=${UPS_MANUFACTURER:-APC}
UPS_Connection=USB

; SNMP Configuration for Synology NAS
EnableSNMP=1
SNMPPort=161
SNMPCommunity=${SNMP_COMMUNITY:-public}

; Shutdown Settings
ShutdownDelay=${SHUTDOWN_DELAY:-180}
LowBatteryThreshold=${BATTERY_THRESHOLD:-15}

; Web Interface
WebInterfacePort=${WEB_PORT:-3052}
EnableWebInterface=1

; Logging
LogFile=/var/log/powerchute.log
LogLevel=${LOG_LEVEL:-INFO}
EOF
fi

# Check for USB devices
echo "Scanning for USB devices..."
if command -v lsusb >/dev/null 2>&1; then
    lsusb
fi

# Start PowerChute agent
echo "Starting PowerChute Serial Shutdown Agent..."
exec ./PowerChute
