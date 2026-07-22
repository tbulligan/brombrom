#!/usr/bin/env python3
import subprocess
import os
import sys

# NDW 'current-state' endpoint provides a full snapshot of traffic signs in NL.
URL = "https://data.ndw.nu/api/rest/static-road-data/traffic-signs/v4/current-state"
JSON_FILE = "ndw_current_state.json"

if os.path.exists(JSON_FILE) and os.path.getsize(JSON_FILE) > 1024 * 1024:
    print(f"File {JSON_FILE} already exists. Skipping download.")
    sys.exit(0)

print("Fetching NDW traffic signs...")
cmd = [
    "curl", "-fL", "--compressed",
    "--connect-timeout", "15",
    "--retry", "5",
    "--retry-delay", "5",
    "--retry-connrefused",
    "--speed-limit", "10240",
    "--speed-time", "30",
    URL,
    "-o", JSON_FILE
]

try:
    subprocess.run(cmd, check=True)
except subprocess.CalledProcessError as e:
    print(f"Error downloading NDW traffic signs: {e}", file=sys.stderr)
    sys.exit(1)

print(f"✓ {JSON_FILE} ({os.path.getsize(JSON_FILE)/1e6:.1f} MB)")
