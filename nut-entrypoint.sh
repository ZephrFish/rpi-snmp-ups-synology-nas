#!/bin/sh
set -e

echo "=== Network UPS Tools (NUT) Server ==="

# Apply timezone
if [ -n "$TZ" ]; then
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
    echo "Timezone: $TZ"
fi

# Update NUT configuration from environment variables
if [ -n "$NUT_LOWBATT" ]; then
    sed -i "s/^LOWBATT .*/LOWBATT $NUT_LOWBATT/" /etc/nut/upsmon.conf
    echo "Low battery threshold: $NUT_LOWBATT%"
fi

if [ -n "$NUT_POLLFREQ" ]; then
    sed -i "s/^POLLFREQ .*/POLLFREQ $NUT_POLLFREQ/" /etc/nut/upsmon.conf
fi

# Override SNMP community
if [ -n "$SNMP_COMMUNITY_RO" ]; then
    sed -i "s/^rocommunity .*/rocommunity $SNMP_COMMUNITY_RO/" /etc/snmp/snmpd.conf
    echo "SNMP RO: $SNMP_COMMUNITY_RO"
fi

# Update ups.conf with custom settings
if [ -n "$UPS_NAME" ]; then
    sed -i "s/^\[ups\]/[$UPS_NAME]/" /etc/nut/ups.conf
    sed -i "s/MONITOR ups@localhost/MONITOR ${UPS_NAME}@localhost/" /etc/nut/upsmon.conf
fi

# Check for USB devices
echo "Scanning for USB devices..."
if command -v lsusb >/dev/null 2>&1; then
    lsusb
fi

# Create state directory
mkdir -p /var/run/nut /var/state/nut /var/log/nut
chmod 770 /var/run/nut /var/state/nut /var/log/nut

# Start NUT driver
echo "Starting NUT driver..."
/usr/lib/nut/usbhid-ups -a ups -D auto 2>&1 &
sleep 2

# Check if driver started successfully
if ! pgrep -f "usbhid-ups" >/dev/null; then
    echo "WARNING: NUT driver may not have started. Check USB device is connected."
fi

# Start NUT server
echo "Starting NUT server..."
upsd -D 2>&1 &
sleep 2

# Test NUT connection
echo "Testing NUT connection..."
if upsc ups@localhost >/dev/null 2>&1; then
    echo "NUT is working!"
    echo ""
    echo "UPS Status:"
    upsc ups@localhost
else
    echo "WARNING: Could not connect to UPS via NUT"
fi

# Start SNMP daemon (for APC OID compatibility)
echo "Starting SNMP daemon..."
/usr/sbin/snmpd -f -LOI -c /etc/snmp/snmpd.conf &
sleep 1

# Start web UI if enabled
if [ "$ENABLE_WEBUI" = "true" ]; then
    echo "Starting Web UI on port 5000..."
    cd /app
    python3 app.py &
fi

# Start upsmon (monitor)
echo "Starting NUT monitor..."
upsmon -D 2>&1 &

echo ""
echo "=== NUT Server Ready ==="
echo "  NUT Port: 3493"
echo "  SNMP Port: 161"
if [ "$ENABLE_WEBUI" = "true" ]; then
    echo "  Web UI: http://localhost:5000"
fi
echo ""
echo "Test commands:"
echo "  upsc ups@localhost          # Get UPS status"
echo "  upscmd -l ups@localhost      # List available commands"
echo ""

# Keep container running
wait
