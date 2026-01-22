#!/bin/sh
set -e

echo "=== UPS SNMP Server Starting ==="

# Apply timezone if set
if [ -n "$TZ" ]; then
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
    echo "Timezone set to $TZ"
fi

# Override SNMP community strings if provided
if [ -n "$SNMP_COMMUNITY_RO" ]; then
    sed -i "s/^rocommunity .*/rocommunity $SNMP_COMMUNITY_RO/" /etc/snmp/snmpd.conf
    echo "SNMP RO community: $SNMP_COMMUNITY_RO"
fi

if [ -n "$SNMP_COMMUNITY_RW" ]; then
    sed -i "s/^rwcommunity .*/rwcommunity $SNMP_COMMUNITY_RW/" /etc/snmp/snmpd.conf
fi

# Override apcupsd battery thresholds if provided
if [ -n "$BATTERYLEVEL" ]; then
    sed -i "s/^BATTERYLEVEL .*/BATTERYLEVEL $BATTERYLEVEL/" /etc/apcupsd/apcupsd.conf
    echo "Battery shutdown level: $BATTERYLEVEL%"
fi

if [ -n "$MINUTES" ]; then
    sed -i "s/^MINUTES .*/MINUTES $MINUTES/" /etc/apcupsd/apcupsd.conf
    echo "Minimum runtime before shutdown: $MINUTES minutes"
fi

# Create NAS shutdown script if credentials provided
if [ -n "$NAS_SSH_HOST" ] && [ -n "$NAS_SSH_USER" ]; then
    cat > /etc/apcupsd/doshutdown << 'EOF'
#!/bin/sh
# Shutdown Synology NAS via SSH when UPS battery is low

NAS_HOST="${NAS_SSH_HOST}"
NAS_USER="${NAS_SSH_USER}"
NAS_SSH_KEY="${NAS_SSH_KEY:-/tmp/nas_key}"

echo "Power failure detected! Shutting down NAS at $NAS_HOST"

# Use SSH key if provided, otherwise use password (less secure)
if [ -f "$NAS_SSH_KEY" ]; then
    ssh -i "$NAS_SSH_KEY" -o StrictHostKeyChecking=no "$NAS_USER@$NAS_HOST" "shutdown -h now"
elif [ -n "$NAS_SSH_PASSWORD" ]; then
    sshpass -p "$NAS_SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$NAS_USER@$NAS_HOST" "shutdown -h now"
fi
EOF
    chmod +x /etc/apcupsd/doshutdown
    echo "NAS shutdown script configured"
fi

# Check for USB devices
echo "Scanning for USB devices..."
if command -v lsusb >/dev/null 2>&1; then
    lsusb
fi

# Test apcaccess before starting services
echo "Testing UPS connection..."
if apcaccess >/dev/null 2>&1; then
    echo "UPS connected successfully!"
    apcaccess
else
    echo "WARNING: Could not connect to UPS. Will continue anyway..."
fi

# Start apcupsd
echo "Starting apcupsd..."
# Create dummy directories for Alpine compatibility
mkdir -p /etc/apcupsd /var/run
touch /etc/apcupsd/powerfail /etc/apcupsd/offbattery /etc/apcupsd/onbattery
/usr/sbin/apcupsd -f /etc/apcupsd/apcupsd.conf

# Wait for apcupsd to be ready
sleep 2

# Start snmpd
echo "Starting snmpd..."
exec /usr/sbin/snmpd -f -LOI -c /etc/snmp/snmpd.conf
