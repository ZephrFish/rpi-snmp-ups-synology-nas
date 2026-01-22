#!/bin/bash
#
# Bare Metal Installation Script for UPS SNMP Server
# Supports: Debian, Ubuntu, Proxmox VE, Alpine Linux
#
# Usage:
#   sudo ./install-bare-metal.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
elif [ -f /etc/alpine-release ]; then
    OS=alpine
else
    log_error "Cannot detect operating system"
    exit 1
fi

log_info "Detected OS: $OS"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (use sudo)"
    exit 1
fi

# Install packages based on OS
case $OS in
    debian|ubuntu|proxmox*)
        log_info "Installing packages for Debian/Ubuntu/Proxmox..."
        apt-get update
        apt-get install -y snmpd snmp apcupsd curl
        ;;
    alpine)
        log_info "Installing packages for Alpine..."
        apk add --no-cache snmpd snmp apcupsd curl
        ;;
    centos|rhel|fedora)
        log_info "Installing packages for RedHat/CentOS/Fedora..."
        if command -v dnf >/dev/null 2>&1; then
            dnf install -y net-snmp net-snmp-utils apcupsd curl
        else
            yum install -y net-snmp net-snmp-utils apcupsd curl
        fi
        ;;
    *)
        log_error "Unsupported OS: $OS"
        exit 1
        ;;
esac

# Create directories
log_info "Setting up directories..."
mkdir -p /etc/snmp
mkdir -p /etc/apcupsd
mkdir -p /var/log/apcupsd

# Install apcupsd.sh script
log_info "Installing SNMP pass-through script..."
cat > /etc/snmp/apcupsd.sh << 'APCSCRIPT'
#!/bin/sh -f
# Check apcupsd is online
apcaccess > /dev/null 2>&1 || exit 0

PLACE=".1.3.6.1.4.1.318.1.1.1"
REQ="$2"

if [ "$1" = "-s" ]; then
    echo $* >> /tmp/passtest.log
    exit 0
fi

if [ "$1" = "-n" ]; then
    case "$REQ" in
    $PLACE| $PLACE.0| $PLACE.0.*| $PLACE.1| $PLACE.1.1.0*) RET=$PLACE.1.1.1.0 ;;
    $PLACE.1*| $PLACE.2.0| $PLACE.2.0.*| $PLACE.2.1| $PLACE.2.2.0*) RET=$PLACE.2.2.1.0 ;;
    $PLACE.2.2.1*) RET=$PLACE.2.2.2.0 ;;
    $PLACE.2.2.2*) RET=$PLACE.2.2.3.0 ;;
    $PLACE.2.2.3*) RET=$PLACE.2.2.4.0 ;;
    $PLACE.2*| $PLACE.3.0*| $PLACE.3.1*| $PLACE.3.2.0*) RET=$PLACE.3.2.1.0 ;;
    $PLACE.3.2.1*| $PLACE.3.2.2*| $PLACE.3.2.3*) RET=$PLACE.3.2.4.0 ;;
    $PLACE.3.2.4*) RET=$PLACE.3.2.5.0 ;;
    $PLACE.3.2*| $PLACE.4.0*| $PLACE.4.1*| $PLACE.4.2.0*) RET=$PLACE.4.2.1.0 ;;
    $PLACE.4.2.1*) RET=$PLACE.4.2.2.0 ;;
    $PLACE.4.2.2*) RET=$PLACE.4.2.3.0 ;;
    $PLACE.4.2.3*) RET=$PLACE.4.2.4.0 ;;
    $PLACE.4.2.*| $PLACE.5*| $PLACE.6*| $PLACE.7.0*| $PLACE.7.1*| $PLACE.7.2.0*| $PLACE.7.2.1*| $PLACE.7.2.2*) RET=$PLACE.7.2.3.0 ;;
    $PLACE.7.2.3*) RET=$PLACE.7.2.4.0 ;;
    $PLACE.7*| $PLACE.8.0*) RET=$PLACE.8.1.0 ;;
    *) exit 0 ;;
    esac
else
    case "$REQ" in
    $PLACE.1.1.1.0| $PLACE.2.2.1.0| $PLACE.2.2.2.0| $PLACE.2.2.3.0| $PLACE.2.2.4.0| \
    $PLACE.3.2.1.0| $PLACE.3.2.4.0| $PLACE.3.2.5.0| $PLACE.4.2.1.0| \
    $PLACE.4.2.2.0| $PLACE.4.2.3.0| $PLACE.4.2.4.0| $PLACE.7.2.3.0| \
    $PLACE.7.2.4.0| $PLACE.8.1.0) RET=$REQ ;;
    *) exit 0 ;;
    esac
fi

echo "$RET"
case "$RET" in
    $PLACE.1.1.1.0) echo "string"; apcaccess -u -p MODEL ; exit 0 ;;
    $PLACE.2.2.1.0) echo "Gauge32"; apcaccess -u -p BCHARGE ; exit 0 ;;
    $PLACE.2.2.2.0) echo "Gauge32"; apcaccess -u -p ITEMP ; exit 0 ;;
    $PLACE.2.2.3.0) echo "Timeticks"; echo $(($(LC_ALL=C printf "%.*f" 0 $(apcaccess -u -p TIMELEFT)) * 6000)) ; exit 0 ;;
    $PLACE.2.2.4.0) echo "string"; apcaccess -u -p BATTDATE ; exit 0 ;;
    $PLACE.3.2.1.0) echo "Gauge32"; apcaccess -u -p LINEV ; exit 0 ;;
    $PLACE.3.2.4.0) echo "Gauge32"; apcaccess -u -p LINEFREQ ; exit 0 ;;
    $PLACE.3.2.5.0) echo "string"; apcaccess -u -p LASTXFER ; exit 0 ;;
    $PLACE.4.2.1.0) echo "Gauge32"; apcaccess -u -p OUTPUTV ; exit 0 ;;
    $PLACE.4.2.2.0) echo "Gauge32"; apcaccess -u -p LINEFREQ ; exit 0 ;;
    $PLACE.4.2.3.0) echo "Gauge32"; apcaccess -u -p LOADPCT ; exit 0 ;;
    $PLACE.4.2.4.0) echo "Gauge32"; apcaccess -u -p LOADPCT ; exit 0 ;;
    $PLACE.7.2.3.0) echo "string"; apcaccess -u -p SELFTEST ; exit 0 ;;
    $PLACE.7.2.4.0) echo "string"; apcaccess -u -p SELFTEST ; exit 0 ;;
    $PLACE.8.1.0) echo "Gauge32"; echo 1 ; exit 0 ;;
    *) echo "string"; echo "ack... $RET $REQ"; exit 0 ;;
esac
APCSCRIPT

chmod +x /etc/snmp/apcupsd.sh

# Backup existing configs
[ -f /etc/snmp/snmpd.conf ] && cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.bak.$(date +%Y%m%d%H%M%S)
[ -f /etc/apcupsd/apcupsd.conf ] && cp /etc/apcupsd/apcupsd.conf /etc/apcupsd/apcupsd.conf.bak.$(date +%Y%m%d%H%M%S)

# Install snmpd.conf
log_info "Installing snmpd configuration..."
cat > /etc/snmp/snmpd.conf << 'SNMPCONF'
# SNMPd Configuration for UPS SNMP Server
agentAddress udp:161,udp6:[::1]:161

# Community strings (CHANGE THESE FOR PRODUCTION!)
rocommunity public
rwcommunity private

# System info
sysLocation Server Room
sysContact admin@example.com
sysName UPS-SNMP-Server

# Pass APC UPS OID tree to shell script
pass .1.3.6.1.4.1.318.1.1.1 /bin/sh /etc/snmp/apcupsd.sh

master agentx
dontLogTCPWrappersConnects yes
SNMPCONF

# Install apcupsd.conf
log_info "Installing apcupsd configuration..."
cat > /etc/apcupsd/apcupsd.conf << 'APCCONF'
## apcupsd.conf v1.1

UPSNAME ups
UPSCABLE usb
UPSTYPE usb
DEVICE

# Shutdown thresholds
BATTERYLEVEL 10
MINUTES 3
TIMEOUT 0

# Notification
ANNOY 300
ANNOYDELAY 60
NOLOGON disable

# Network Information Server
NETSERVER on
NISIP 0.0.0.0
NISPORT 3551

# Events
ONBATTERYDELAY 6
BATTERYLEVEL 10
MINUTES 3
TIMEOUT 0

# Shutdown script
SHUTDOWN /etc/apcupsd/doshutdown
APCCONF

# Install shutdown script
log_info "Installing shutdown script..."
cat > /etc/apcupsd/doshutdown << 'SHUTDOWNSCRIPT'
#!/bin/sh
LOG_FILE="/var/log/apcupsd-events.log"

log_event() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_event "=== UPS SHUTDOWN EVENT TRIGGERED ==="

BATTERY_CHARGE=$(apcaccess -u -p BCHARGE 2>/dev/null || echo "unknown")
TIME_LEFT=$(apcaccess -u -p TIMELEFT 2>/dev/null || echo "unknown")

log_event "Battery: ${BATTERY_CHARGE}% | Runtime: ${TIME_LEFT} minutes"

# Send SNMP trap to Synology NAS if configured
if [ -n "$SYNOLOGY_NAS_IP" ]; then
    log_event "Sending SNMP trap to Synology NAS at $SYNOLOGY_NAS_IP"
    if command -v snmptrap >/dev/null 2>&1; then
        snmptrap -v 2c -c "${SNMP_COMMUNITY:-public}" "$SYNOLOGY_NAS_IP" '' \
            .1.3.6.1.4.1.318.0.9 \
            .1.3.6.1.2.1.1.3.0 int 0 \
            .1.3.6.1.2.1.1.1.0 s "UPS Battery Low" \
            .1.3.6.1.4.1.318.1.1.1.2.2.1.0 i "${BATTERY_CHARGE}" 2>&1 | tee -a "$LOG_FILE"
    fi
fi

# Optional: Call webhook
if [ -n "$SHUTDOWN_WEBHOOK" ]; then
    log_event "Calling shutdown webhook"
    curl -s "$SHUTDOWN_WEBHOOK" >> "$LOG_FILE" 2>&1
fi

log_event "Shutdown script completed"
exit 0
SHUTDOWNSCRIPT

chmod +x /etc/apcupsd/doshutdown

# Create event scripts
cat > /etc/apcupsd/onbattery << 'ONBATTERY'
#!/bin/sh
echo "[$(date)] Power failure detected - UPS on battery" >> /var/log/apcupsd-events.log
ONBATTERY
chmod +x /etc/apcupsd/onbattery

cat > /etc/apcupsd/offbattery << 'OFFBATTERY'
#!/bin/sh
echo "[$(date)] Power restored" >> /var/log/apcupsd-events.log
OFFBATTERY
chmod +x /etc/apcupsd/offbattery

# Proxmox/Debian: fix permissions
if [ "$OS" != "alpine" ]; then
    log_info "Fixing file permissions..."
    chmod 644 /etc/snmp/snmpd.conf
    chmod 644 /etc/apcupsd/apcupsd.conf
fi

# Enable and start services
log_info "Enabling and starting services..."
case $OS in
    debian|ubuntu|proxmox*)
        systemctl enable apcupsd 2>/dev/null || true
        systemctl enable snmpd 2>/dev/null || true
        systemctl restart apcupsd
        systemctl restart snmpd
        ;;
    alpine)
        rc-update add apcupsd default 2>/dev/null || true
        rc-update add snmpd default 2>/dev/null || true
        rc-service apcupsd restart
        rc-service snmpd restart
        ;;
    centos|rhel|fedora)
        systemctl enable apcupsd 2>/dev/null || true
        systemctl enable snmpd 2>/dev/null || true
        systemctl restart apcupsd
        systemctl restart snmpd
        ;;
esac

# Test UPS connection
log_info "Testing UPS connection..."
sleep 2
if apcaccess >/dev/null 2>&1; then
    log_info "UPS connected successfully!"
    echo ""
    apcaccess
else
    log_warn "Could not connect to UPS. Please check:"
    log_warn "  - USB device is connected"
    log_warn "  - Run 'lsusb' to verify device is visible"
    log_warn "  - Check dmesg for USB errors"
fi

echo ""
log_info "Installation complete!"
echo ""
echo "Testing SNMP query..."
if snmpwalk -v 2c -c public 127.0.0.1 .1.3.6.1.4.1.318.1.1.1.1.1.1.0 >/dev/null 2>&1; then
    log_info "SNMP is working!"
    MODEL=$(snmpwalk -v 2c -c public 127.0.0.1 .1.3.6.1.4.1.318.1.1.1.1.1.1.0 2>/dev/null | grep -oP 'STRING: "\K[^"]+')
    echo "  UPS Model: $MODEL"
else
    log_warn "SNMP query failed. Check with: snmpwalk -v 2c -c public 127.0.0.1 .1.3.6.1.4.1.318.1.1.1"
fi

echo ""
echo "Next steps:"
echo "  1. Configure Synology NAS UPS settings (see README.md)"
echo "  2. Set SYNOLOGY_NAS_IP in /etc/default/apcupsd for SNMP trap notifications"
echo "  3. Test with: snmpwalk -v 2c -c public <this-ip> .1.3.6.1.4.1.318.1.1.1"
