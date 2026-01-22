#!/bin/bash
#
# Convert PowerChute RPM to DEB using Docker
# Usage: ./convert-rpm-to-deb.sh /path/to/pcssagent.rpm
#

RPM_FILE="$1"

if [ -z "$RPM_FILE" ]; then
    echo "Usage: $0 /path/to/pcssagent-*.x86_64.rpm"
    exit 1
fi

if [ ! -f "$RPM_FILE" ]; then
    echo "ERROR: File not found: $RPM_FILE"
    exit 1
fi

RPM_DIR="$(dirname "$RPM_FILE")"
RPM_NAME="$(basename "$RPM_FILE")"

echo "=== Converting PowerChute RPM to DEB ==="
echo "RPM: $RPM_FILE"

# Run Debian container with alien to convert
docker run --rm -v "$RPM_DIR:/input" -w /output debian:bookworm-slim bash -c "
    apt-get update && apt-get install -y alien
    cd /input
    echo 'Converting RPM to DEB...'
    alien --to-deb --scripts '$RPM_NAME'
    ls -lh *.deb 2>/dev/null || echo 'Conversion may have failed'
    echo ''
    echo 'DEB file created in: $RPM_DIR'
"

echo ""
echo "Done! Check the directory for the .deb file."
