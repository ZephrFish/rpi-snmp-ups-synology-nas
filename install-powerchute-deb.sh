#!/bin/sh
set -e

# PowerChute Installation Script for Debian/Ubuntu
# Converts RPM to DEB package

INSTALL_DIR="/opt/APC/PowerChuteSerialShutdown"
RPM_FILE="/tmp/pcssagent.rpm"

echo "=== PowerChute Installation for Debian/Ubuntu ==="

# Check if RPM is provided
if [ ! -f "$RPM_FILE" ]; then
    echo "ERROR: PowerChute RPM not found at $RPM_FILE"
    echo "Please mount the RPM file:"
    echo "  docker run -v /path/to/pcssagent-*.x86_64.rpm:/tmp/pcssagent.rpm ..."
    exit 1
fi

# Install alien if not present
if ! command -v alien >/dev/null 2>&1; then
    echo "Installing alien package converter..."
    apt-get update
    apt-get install -y alien
fi

# Convert RPM to DEB
echo "Converting RPM to DEB package..."
DEB_FILE=$(alien --to-deb --scripts "$RPM_FILE" 2>&1 | grep -oP 'pcssagent.*\.deb' || true)

if [ -z "$DEB_FILE" ]; then
    # Try to find the generated deb file
    DEB_FILE=$(ls pcssagent*.deb 2>/dev/null | head -n1)
fi

if [ -z "$DEB_FILE" ] || [ ! -f "$DEB_FILE" ]; then
    echo "ERROR: Failed to convert RPM to DEB"
    echo "Trying alternative method: direct RPM extraction..."

    # Alternative: Extract RPM directly
    mkdir -p /tmp/rpm-extract
    cd /tmp/rpm-extract

    # Use rpm2cpio if available, or install it
    if ! command -v rpm2cpio >/dev/null 2>&1; then
        apt-get install -y rpm2cpio
    fi

    # Extract RPM
    rpm2cpio "$RPM_FILE" | cpio -idmv

    # Copy files to target directory
    mkdir -p "$INSTALL_DIR/Agent"
    cp -r opt/APC/PowerChuteSerialShutdown/* "$INSTALL_DIR/" 2>/dev/null || true

    # If extraction didn't work as expected, try another method
    if [ ! -d "$INSTALL_DIR/Agent" ] || [ -z "$(ls -A "$INSTALL_DIR/Agent" 2>/dev/null)" ]; then
        echo "Attempting binutils extraction..."
        apt-get install -y binutils
        rpm2cpio "$RPM_FILE" | cpio -idmv ./opt/APC/PowerChuteSerialShutdown/Agent/*

        # Create directory structure
        mkdir -p "$INSTALL_DIR/Agent"
        cp -r opt/APC/PowerChuteSerialShutdown/* "$INSTALL_DIR/"
    fi

    cd - >/dev/null
    rm -rf /tmp/rpm-extract
else
    # Install DEB package
    echo "Installing DEB package..."
    dpkg -i "$DEB_FILE" || true

    # Fix any missing dependencies
    apt-get install -f -y

    # Clean up
    rm -f "$DEB_FILE"
fi

# Verify installation
if [ -d "$INSTALL_DIR/Agent" ]; then
    echo "PowerChute installed to $INSTALL_DIR"

    # Make scripts executable
    find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    chmod +x "$INSTALL_DIR/Agent/PowerChute" 2>/dev/null || true

    # Create configuration if not exists
    if [ ! -f "$INSTALL_DIR/Agent/config.ini" ]; then
        cat > "$INSTALL_DIR/Agent/config.ini" << 'EOF'
[PowerChute]
UPS_Manufacturer=APC
UPS_Connection=USB
EnableSNMP=1
SNMPPort=161
SNMPCommunity=public
ShutdownDelay=180
LowBatteryThreshold=15
WebInterfacePort=3052
EnableWebInterface=1
LogFile=/var/log/powerchute.log
LogLevel=INFO
EOF
    fi

    echo "Installation complete!"
else
    echo "WARNING: Installation may not be complete"
    echo "Directory $INSTALL_DIR/Agent not found or empty"
    exit 1
fi
