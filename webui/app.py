#!/usr/bin/env python3
"""
UPS Web Monitor - Flask Web UI for UPS Monitoring
Provides a modern web interface for apcupsd UPS status
"""

from flask import Flask, render_template, jsonify
import subprocess
import re
import os
from datetime import datetime

app = Flask(__name__)

def get_apcaccess():
    """Get UPS status from apcaccess command"""
    try:
        result = subprocess.run(
            ['apcaccess'],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            return parse_apcaccess(result.stdout)
        return None
    except Exception as e:
        return {"error": str(e)}

def parse_apcaccess(output):
    """Parse apcaccess output into dictionary"""
    data = {}
    for line in output.split('\n'):
        match = re.match(r'^\s*([^:]+)\s*:\s*(.+?)\s*$', line)
        if match:
            key = match.group(1).strip()
            value = match.group(2).strip()
            data[key] = value
    return data

def get_snmp_status():
    """Check if SNMP is running"""
    try:
        result = subprocess.run(
            ['pgrep', 'snmpd'],
            capture_output=True,
            text=True
        )
        return result.returncode == 0
    except:
        return False

@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('index.html')

@app.route('/api/status')
def api_status():
    """API endpoint for UPS status"""
    status = get_apcaccess()

    if status and 'error' not in status:
        # Convert to more usable format
        return jsonify({
            'success': True,
            'timestamp': datetime.now().isoformat(),
            'snmp_running': get_snmp_status(),
            'ups': {
                'model': status.get('MODEL', 'Unknown'),
                'status': status.get('STATUS', 'Unknown'),
                'battery_charge': status.get('BCHARGE', '0').replace('%', ''),
                'battery_voltage': status.get('BATTV', 'Unknown'),
                'battery_temperature': status.get('ITEMP', 'Unknown'),
                'time_left': status.get('TIMELEFT', 'Unknown'),
                'input_voltage': status.get('LINEV', 'Unknown'),
                'input_frequency': status.get('LINEFREQ', 'Unknown'),
                'output_voltage': status.get('OUTPUTV', 'Unknown'),
                'load_percent': status.get('LOADPCT', '0').replace('%', ''),
                'last_transfer': status.get('LASTXFER', 'Unknown'),
                'battery_date': status.get('BATTDATE', 'Unknown'),
                'serial_number': status.get('SERIALNO', 'Unknown'),
                'firmware': status.get('FIRMWARE', 'Unknown'),
                'selftest': status.get('SELFTEST', 'Unknown')
            }
        })
    else:
        return jsonify({
            'success': False,
            'error': status.get('error', 'Unable to communicate with UPS') if status else 'UPS not responding'
        }), 503

@app.route('/api/config')
def api_config():
    """Get current configuration"""
    config = {}

    # Get apcupsd config
    try:
        with open('/etc/apcupsd/apcupsd.conf', 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    if ' ' in line:
                        key, value = line.split(None, 1)
                        config[key] = value
    except:
        pass

    return jsonify({'success': True, 'config': config})

@app.route('/api/test-snmp')
def api_test_snmp():
    """Test SNMP query"""
    try:
        result = subprocess.run([
            'snmpwalk', '-v', '2c', '-c', 'public', '127.0.0.1',
            '.1.3.6.1.4.1.318.1.1.1.1.1.1.0'
        ], capture_output=True, text=True, timeout=5)

        if result.returncode == 0:
            return jsonify({
                'success': True,
                'response': result.stdout.strip()
            })
        else:
            return jsonify({
                'success': False,
                'error': result.stderr
            })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/health')
def health():
    """Health check endpoint"""
    status = get_apcaccess()
    healthy = status and 'error' not in status
    return ('', 200) if healthy else ('', 503)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
