# UPS SNMP Server for Proxmox + Synology NAS

A comprehensive UPS monitoring solution for Proxmox + Synology NAS, supporting multiple UPS brands via Network UPS Tools (NUT).

**Five deployment options available:**
1. **Docker with NUT** - Industry standard, supports 200+ UPS models
2. **Docker with apcupsd** - Lightweight, APC-specific
3. **Docker with Web UI** - Modern dashboard + apcupsd
4. **Docker with PowerChute** - Official Schneider Electric software
5. **Bare Metal** - Direct installation on Proxmox/Debian/Ubuntu/Alpine

---

## Quick Comparison

| Feature | NUT | apcupsd | Web UI | PowerChute |
|---------|-----|---------|--------|------------|
| UPS Brands Supported | **200+** | APC only | APC only | APC only |
| Size | ~150MB | ~50MB | ~200MB | ~200MB+ |
| Web Interface | No | No | **Yes (5000)** | Yes (3052) |
| SNMP Support | **Yes** | Yes | Yes | Yes |
| Real-time graphs | No | No | **Yes** | No |
| Configuration | Text | Text | Web + Text | Web + Text |
| License | GPL | GPL | GPL | Proprietary |
| **Recommended** | **Yes** | | | |

---

## Option 1: Docker with NUT (Recommended)

**Network UPS Tools (NUT)** is the industry-standard UPS monitoring solution for Linux, supporting over 200 UPS models from APC, CyberPower, Eaton, Tripp Lite, and more.

### Features

- **200+ UPS Models Supported** - APC, CyberPower, Eaton, Tripp Lite, etc.
- **Multiple Protocols** - USB, Serial, SNMP, Network
- **Proven & Stable** - Used in enterprise environments worldwide
- **Client-Server Architecture** - Can monitor multiple UPS devices
- **Built-in SNMP** - Exposes UPS data via standard protocols
- **Synology Compatible** - Works with DSM UPS monitoring

### Setup

```bash
cd docker-ups-snmp

# Build and start with NUT
docker compose -f docker-compose.nut.yml up -d

# Check UPS status
docker exec nut-ups-server upsc ups@localhost
```

### Supported UPS Drivers

| Driver | Protocol | Compatible Brands |
|--------|----------|-------------------|
| `usbhid-ups` | USB | APC, CyberPower, Eaton, Tripp Lite, most USB UPS |
| `snmp-ups` | SNMP | APC, Eaton, most network-connected UPS |
| `apcsmart` | Serial | Older APC with serial cable |
| `blazer_ser` | Serial | Many generic serial UPS |
| `netxml-ups` | Network | Eaton, others with XML protocol |

### NUT Commands

```bash
# Get all UPS data
upsc ups@localhost

# Get specific value
upsc ups@localhost battery.charge

# List available commands
upscmd -l ups@localhost

# Test beeper (if supported)
upscmd ups@localhost beeper.toggle
```

### Configuration

Edit `nut/ups.conf` to use a different driver or add multiple UPS:

```ini
[apc-usb]
    driver = usbhid-ups
    port = auto

[cyberpower]
    driver = usbhid-ups
    port = auto
    vendorid = 0764

[eaton-network]
    driver = snmp-ups
    port = 192.168.1.100
    community = public
```

---

## Option 2: Docker with apcupsd (APC Only)

### Quick Start

```bash
cd docker-ups-snmp

# Edit docker-compose.yml to set your NAS IP
# Set SYNOLOGY_NAS_IP=192.168.1.X

# Build and start
docker compose up -d
```

### Verify UPS Connection

```bash
# Check UPS is connected
docker exec ups-snmp-server apcaccess

# Test SNMP is working
snmpwalk -v 2c -c public 127.0.0.1 .1.3.6.1.4.1.318.1.1.1
```

---

## Option 3: Docker with Web UI

A modern web interface for monitoring your UPS with real-time status updates.

### Features

- **Modern Dashboard** - Clean, responsive web UI
- **Real-time Updates** - Auto-refreshes every 5 seconds
- **Battery Monitoring** - Visual battery percentage with color coding
- **SNMP Status** - Shows if SNMP is running
- **Complete UPS Info** - Model, serial, firmware, voltages, temps

### Setup

```bash
cd docker-ups-snmp

# Build and start with Web UI
docker compose -f docker-compose.webui.yml up -d

# Access web interface at http://<host-ip>:5000
```

### Screenshot Preview

The dashboard shows:
- Battery charge with progress bar (green → yellow → red)
- Time remaining on battery
- Current load percentage
- Input/output voltages
- Full UPS information panel

---

## Option 4: Docker with PowerChute

PowerChute is the official APC/Schneider Electric management software with a web interface.

### Setup

```bash
cd docker-ups-snmp

# Copy the PowerChute RPM to this directory
cp /path/to/pcssagent-1.4.0-301-EN.x86_64.rpm .

# Build and start with PowerChute
docker compose -f docker-compose.powerchute.yml up -d

# Access web interface at http://<host-ip>:3052
```

### PowerChute Features

- Web-based configuration (port 3052)
- Built-in SNMP agent
- Email notifications
- Detailed event logging
- Multi-UPS support (network + USB)

---

## Option 5: Bare Metal Installation

Install directly on Proxmox host, Debian, Ubuntu, or Alpine Linux.

```bash
# Download and run installer
cd docker-ups-snmp
sudo ./install-bare-metal.sh
```

The script will:
- Detect your OS
- Install required packages (snmpd, apcupsd)
- Configure SNMP pass-through for APC OIDs
- Enable and start services

### Proxmox LXC (Alternative)

```bash
# Create LXC container
pct create 100 local:vztmpl/alpine-3.20-default_20240719_amd64.tar.zst \
  --rootfs local-lvm:8 --net0 name=eth0,bridge=vmbr0,ip=dhcp

# Pass through USB device (find your device with lsusb)
pct set 100 -mp0=/dev/bus/usb/001/002,mp=/dev/bus/usb/001/002

# Run installer inside container
pct push 100 install-bare-metal.sh /tmp/install.sh
pct exec 100 -- sh /tmp/install.sh
```

---

## Synology NAS Configuration

### Step 1: Enable UPS Support in DSM

1. Log in to Synology DSM as administrator
2. Go to **Control Panel** > **Hardware & Power** > **UPS**
3. Check **Enable UPS Support**
4. Select **Network UPS** as the UPS type
5. Click **Apply**

### Step 2: Configure SNMP UPS Device

1. In the UPS configuration, click **Add**
2. Set the following:
   - **UPS Type**: `snmpups` (Synology's SNMP driver)
   - **Device Address**: `<IP_ADDRESS_OF_HOST>` (e.g., `192.168.1.50`)
   - **Community**: `public` (or your SNMP_COMMUNITY_RO value)
   - **SNMP Version**: `v2c`

### Step 3: Configure Shutdown Settings

| Setting | Recommended Value | Description |
|---------|-------------------|-------------|
| **UPS Type** | Network UPS (snmpups) | SNMP-based monitoring |
| **Time before Synology NAS shuts down** | 2-5 minutes | Time to wait before shutdown |
| **Enable "Safe Mode"** | Yes | Continue shutdown even if UPS not detected |

### Threshold Strategy

| Component | Setting | Result |
|-----------|---------|--------|
| Container | 15% battery | Sends shutdown signal at 15% |
| Synology | Shutdown at 2 min | Initiates graceful shutdown |

This ensures Synology completes its shutdown sequence before battery is depleted.

---

## Configuration Reference

### Environment Variables (apcupsd)

| Variable | Default | Description |
|----------|---------|-------------|
| `TZ` | UTC | Timezone for logs |
| `SNMP_COMMUNITY_RO` | public | SNMP read-only community |
| `SNMP_COMMUNITY_RW` | private | SNMP read-write community |
| `SYNOLOGY_NAS_IP` | - | Synology IP for SNMP traps |
| `BATTERYLEVEL` | 15 | Battery % to trigger shutdown |
| `MINUTES` | 5 | Runtime minutes to trigger shutdown |
| `NAS_SSH_HOST` | - | NAS IP for SSH fallback |
| `NAS_SSH_USER` | - | SSH username |
| `SHUTDOWN_WEBHOOK` | - | Webhook for notifications |

### Environment Variables (PowerChute)

| Variable | Default | Description |
|----------|---------|-------------|
| `SNMP_COMMUNITY` | public | SNMP community string |
| `BATTERY_THRESHOLD` | 15 | Low battery threshold % |
| `SHUTDOWN_DELAY` | 180 | Seconds before shutdown |
| `WEB_PORT` | 3052 | Web interface port |

---

## SNMP OID Reference

The following APC-compatible OIDs are exposed:

| OID | Description | Type |
|-----|-------------|------|
| `.1.3.6.1.4.1.318.1.1.1.1.1.1.0` | UPS Model | string |
| `.1.3.6.1.4.1.318.1.1.1.2.2.1.0` | Battery Charge % | Gauge32 |
| `.1.3.6.1.4.1.318.1.1.1.2.2.2.0` | Battery Temperature | Gauge32 |
| `.1.3.6.1.4.1.318.1.1.1.2.2.3.0` | Time Remaining | Timeticks |
| `.1.3.6.1.4.1.318.1.1.1.2.2.4.0` | Battery Date | string |
| `.1.3.6.1.4.1.318.1.1.1.3.2.1.0` | Input Voltage | Gauge32 |
| `.1.3.6.1.4.1.318.1.1.1.3.2.4.0` | Input Frequency | Gauge32 |
| `.1.3.6.1.4.1.318.1.1.1.3.2.5.0` | Last Transfer Reason | string |
| `.1.3.6.1.4.1.318.1.1.1.4.2.1.0` | Output Voltage | Gauge32 |
| `.1.3.6.1.4.1.318.1.1.1.4.2.3.0` | Load % | Gauge32 |

---

## Testing

### Test SNMP Query

```bash
# From any machine on the network:
snmpwalk -v 2c -c public <HOST_IP> .1.3.6.1.4.1.318.1.1.1

# Expected output:
# .1.3.6.1.4.1.318.1.1.1.1.1.1.0 = STRING: "Back-UPS RS 1500G"
# .1.3.6.1.4.1.318.1.1.1.2.2.1.0 = Gauge32: 100
# .1.3.6.1.4.1.318.1.1.1.4.2.3.0 = Gauge32: 15
```

### Verify Synology Detection

In Synology DSM:
1. Go to **Control Panel** > **Hardware & Power** > **UPS**
2. Click **Test Connection**
3. Should show "Connected successfully" with UPS details

---

## Troubleshooting

### UPS Not Detected

```bash
# Check USB devices
lsusb

# Check apcupsd status
apcaccess

# Check container logs
docker logs ups-snmp-server
```

### SNMP Not Working

```bash
# Verify snmpd is running
ps aux | grep snmpd

# Test locally
snmpwalk -v 2c -c public 127.0.0.1 .1.3.6.1.4.1.318.1.1.1

# Check firewall (port 161/udp)
```

### Synology Not Shutting Down

1. Verify SNMP from Synology:
   ```bash
   # SSH into Synology and test
   snmpwalk -v 2c -c public <HOST_IP> .1.3.6.1.4.1.318.1.1.1
   ```
2. Check Synology UPS logs in DSM
3. Ensure community string matches

---

## File Structure

```
docker-ups-snmp/
├── Dockerfile                      # apcupsd container (Alpine)
├── Dockerfile.nut                  # NUT container (Debian) ⭐ NEW
├── Dockerfile.webui                # Web UI container (Debian)
├── Dockerfile.powerchute           # PowerChute container (Rocky)
├── Dockerfile.ubuntu               # PowerChute container (Debian/Ubuntu)
├── docker-compose.yml              # apcupsd deployment
├── docker-compose.nut.yml          # NUT deployment ⭐ NEW
├── docker-compose.webui.yml        # Web UI deployment
├── docker-compose.powerchute.yml   # PowerChute deployment
├── docker-entrypoint.sh            # apcupsd startup
├── nut-entrypoint.sh               # NUT startup ⭐ NEW
├── webui-entrypoint.sh             # Web UI startup
├── powerchute-entrypoint.sh        # PowerChute startup (Rocky)
├── powerchute-entrypoint-deb.sh    # PowerChute startup (Debian/Ubuntu)
├── nut/                            # NUT configuration ⭐ NEW
│   ├── ups.conf                    # Driver configuration
│   ├── upsd.conf                   # Server configuration
│   ├── upsmon.conf                 # Monitor configuration
│   └── nut.conf                    # Global settings
├── install-bare-metal.sh           # Bare metal installer
├── convert-rpm-to-deb.sh           # RPM to DEB converter
├── webui/
│   ├── app.py                      # Flask web application
│   └── templates/
│       └── index.html              # Web UI dashboard
├── snmpd.conf                      # SNMP config
├── apcupsd.conf                    # apcupsd config
├── apcupsd.sh                      # SNMP pass-through script
├── doshutdown                      # Shutdown trigger script
├── onbattery                       # Power failure event script
├── offbattery                      # Power restore event script
└── README.md                       # This file
```

---

## License

MIT License - Based on https://github.com/ZephrFish/rpi-snmp-ups-synology-nas
