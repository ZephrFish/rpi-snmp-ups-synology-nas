#!/bin/sh
set -e

echo "=== UPS Monitor with Web UI ==="

# Apply timezone if set
if [ -n "$TZ" ]; then
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
    echo "Timezone: $TZ"
fi

# Override SNMP community strings
if [ -n "$SNMP_COMMUNITY_RO" ]; then
    sed -i "s/^rocommunity .*/rocommunity $SNMP_COMMUNITY_RO/" /etc/snmp/snmpd.conf
    echo "SNMP RO: $SNMP_COMMUNITY_RO"
fi

if [ -n "$SNMP_COMMUNITY_RW" ]; then
    sed -i "s/^rwcommunity .*/rwcommunity $SNMP_COMMUNITY_RW/" /etc/snmp/snmpd.conf
fi

# Override apcupsd settings
if [ -n "$BATTERYLEVEL" ]; then
    sed -i "s/^BATTERYLEVEL .*/BATTERYLEVEL $BATTERYLEVEL/" /etc/apcupsd/apcupsd.conf
    echo "Battery threshold: $BATTERYLEVEL%"
fi

if [ -n "$MINUTES" ]; then
    sed -i "s/^MINUTES .*/MINUTES $MINUTES/" /etc/apcupsd/apcupsd.conf
    echo "Runtime threshold: $MINUTES minutes"
fi

# Check for USB devices
echo "USB devices:"
lsusb 2>/dev/null || echo "No USB devices detected yet"

# Test UPS connection
echo "Testing UPS..."
if apcaccess >/dev/null 2>&1; then
    echo "UPS connected!"
    apcaccess
else
    echo "WARNING: Could not connect to UPS"
fi

# Start apcupsd in background
echo "Starting apcupsd..."
/usr/sbin/apcupsd -f /etc/apcupsd/apcupsd.conf &
sleep 2

# Start snmpd in background
echo "Starting snmpd..."
/usr/sbin/snmpd -f -LOI -c /etc/snmp/snmpd.conf &
sleep 1

# Start web UI
echo "Starting Web UI on port $WEB_PORT..."
echo "Access at: http://localhost:$WEB_PORT"
cd /app

# Start both web UI and wait for background processes
exec python3 app.py &
wait
