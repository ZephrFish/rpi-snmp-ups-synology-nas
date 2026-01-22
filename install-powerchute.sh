#!/bin/sh
set -e

# PowerChute Serial Shutdown Installation Script for Docker
# This script installs the PowerChute agent from the RPM

INSTALL_DIR="/opt/APC/PowerChuteSerialShutdown"
RPM_FILE="/tmp/pcssagent.rpm"

echo "=== PowerChute Installation Script ==="

# Check if RPM is provided
if [ ! -f "$RPM_FILE" ]; then
    echo "ERROR: PowerChute RPM not found at $RPM_FILE"
    echo "Please mount or copy the RPM file to /tmp/pcssagent.rpm"
    echo ""
    echo "Usage: docker run -v /path/to/pcssagent-*.x86_64.rpm:/tmp/pcssagent.rpm ..."
    exit 1
fi

# Install PowerChute from RPM
echo "Installing PowerChute from RPM..."
rpm -i --prefix="$INSTALL_DIR" "$RPM_FILE" || {
    echo "Installation failed. Checking for errors..."
    if [ -f ./rpm.log ]; then
        cat ./rpm.log
    fi
    exit 1
}

echo "PowerChute installed to $INSTALL_DIR"

# Create a minimal configuration if not exists
if [ ! -f "$INSTALL_DIR/Agent/config.ini" ]; then
    echo "Creating default configuration..."
    cat > "$INSTALL_DIR/Agent/config.ini" << 'EOF'
[PowerChute]
; PowerChute Serial Shutdown Configuration

; UPS Communication
UPS_Manufacturer=APC
UPS_Model=Auto-Detect
UPS_Connection=USB

; Network Settings
; Enable SNMP Master Agent to communicate with Synology NAS
EnableSNMP=1
SNMPPort=161
SNMPCommunity=public

; Shutdown Settings
; Time to wait before shutdown after power loss (in seconds)
ShutdownDelay=180

; Battery threshold for shutdown (percentage)
LowBatteryThreshold=15

; Web Interface
WebInterfacePort=3052
EnableWebInterface=1

; Logging
LogFile=/var/log/powerchute.log
LogLevel=INFO
EOF
fi

# Make scripts executable
chmod +x "$INSTALL_DIR/Agent/PowerChute" 2>/dev/null || true
chmod +x "$INSTALL_DIR/Agent/*.sh" 2>/dev/null || true

echo "Installation complete!"
echo ""
echo "Next: Configure PowerChute by editing $INSTALL_DIR/Agent/config.ini"
echo "      or use the web interface at http://<container-ip>:3052"
