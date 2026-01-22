# SNMP UPS Server Docker Image
# For use on Proxmox/LXC to expose USB UPS to Synology NAS via SNMP
FROM alpine:3.20

# Install required packages
RUN apk add --no-cache \
    snmpd \
    snmp \
    apcupsd \
    bind-tools \
    udev \
    usbutils \
    bash

# Create directories
RUN mkdir -p /etc/snmp /var/run/apcupsd /etc/apcupsd

# Copy configuration files
COPY snmpd.conf /etc/snmp/snmpd.conf
COPY apcupsd.conf /etc/apcupsd/apcupsd.conf
COPY apcupsd.sh /etc/snmp/apcupsd.sh
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Make scripts executable
RUN chmod +x /etc/snmp/apcupsd.sh /usr/local/bin/docker-entrypoint.sh

# Create apcupsd powerfail script for NAS shutdown
RUN mkdir -p /etc/apcupsd
COPY doshutdown /etc/apcupsd/doshutdown
RUN chmod +x /etc/apcupsd/doshutdown

# Expose SNMP port
EXPOSE 161/udp

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD snmpwalk -v 2c -c public 127.0.0.1 .1.3.6.1.4.1.318.1.1.1.1.1.1.0 || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
