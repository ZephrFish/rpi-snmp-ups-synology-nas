#!/bin/sh
set -e

echo "=== APC PowerChute Serial Shutdown - Debian/Ubuntu ==="

# Install on first run if RPM is provided
if [ -f /tmp/pcssagent.rpm ] && [ ! -d /opt/APC/PowerChuteSerialShutdown/Agent ]; then
    echo "Installing PowerChute RPM (converting to DEB)..."
    /tmp/install-powerchute-deb.sh
fi

# Check installation
if [ ! -d /opt/APC/PowerChuteSerialShutdown/Agent ]; then
    echo "ERROR: PowerChute not installed!"
    echo "Please provide the PowerChute RPM:"
    echo "  docker run -v /path/to/pcssagent.rpm:/tmp/pcssagent.rpm ..."
    exit 1
fi

cd /opt/APC/PowerChuteSerialShutdown/Agent

# Create or update configuration
cat > config.ini << EOF
[PowerChute]
UPS_Manufacturer=${UPS_MANUFACTURER:-APC}
UPS_Connection=USB

; SNMP for Synology NAS
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

# Check USB devices
echo "USB devices:"
lsusb 2>/dev/null || echo "No lsusb available"

# Start PowerChute
echo "Starting PowerChute..."
exec ./PowerChute
