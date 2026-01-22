# Dockerfile for Network UPS Tools (NUT)
# The industry-standard UPS monitoring solution for Linux

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install NUT and dependencies
RUN apt-get update && apt-get install -y \
    nut \
    nut-client \
    nut-server \
    nut-snmp \
    snmpd \
    snmp \
    python3 \
    python3-pip \
    curl \
    usbutils \
    && rm -rf /var/lib/apt/lists/*

# Install Python for web UI (optional, for monitoring)
RUN pip3 install --no-cache-dir \
    flask \
    flask-cors \
    psutil 2>/dev/null || true

# Create directories
RUN mkdir -p /etc/nut /var/run/nut /var/log/nut /var/state/nut \
    /etc/nut/devices.d /app/templates

# Copy NUT configuration files
COPY nut/ups.conf /etc/nut/ups.conf
COPY nut/upsd.conf /etc/nut/upsd.conf
COPY nut/upsmon.conf /etc/nut/upsmon.conf
COPY nut/nut.conf /etc/nut/nut.conf

# Fix permissions for NUT
RUN chmod 640 /etc/nut/*.conf \
    && chown root:nut /etc/nut/*.conf \
    && chmod +x /var/run/nut /var/log/nut /var/state/nut

# Copy SNMP configuration (for APC OID compatibility)
COPY snmpd.conf /etc/snmp/snmpd.conf
COPY apcupsd.sh /etc/snmp/apcupsd.sh
RUN chmod +x /etc/snmp/apcupsd.sh

# Copy event scripts
COPY onbattery /etc/nut/onbattery
COPY offbattery /etc/nut/offbattery
COPY doshutdown /etc/nut/doshutdown
RUN chmod +x /etc/nut/onbattery /etc/nut/offbattery /etc/nut/doshutdown

# Copy web UI (reuse from webui)
COPY webui/app.py /app/
COPY webui/templates /app/templates/

# Copy entrypoint
COPY nut-entrypoint.sh /usr/local/bin/nut-entrypoint.sh
RUN chmod +x /usr/local/bin/nut-entrypoint.sh

# Expose NUT ports
# 3493 - NUT server port
# 5000 - Optional web UI
# 161/udp - SNMP
EXPOSE 3493 5000 161/udp

WORKDIR /app

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD upsc ups@localhost >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/usr/local/bin/nut-entrypoint.sh"]
