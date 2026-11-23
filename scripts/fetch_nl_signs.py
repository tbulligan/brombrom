#!/usr/bin/env python3
import subprocess
import os
import sys

# NDW 'current-state' endpoint provides a full snapshot of traffic signs in NL.
URL = "https://data.ndw.nu/api/rest/static-road-data/traffic-signs/v4/current-state"
JSON_FILE = "ndw_current_state.json"
TMP_FILE = f"{JSON_FILE}.tmp"

if os.path.exists(JSON_FILE) and os.path.getsize(JSON_FILE) > 1024 * 1024:
    print(f"File {JSON_FILE} already exists. Skipping download.")
    sys.exit(0)

print("Fetching NDW traffic signs...")
cmd = [
    "curl", "-fL", "--compressed",
    "--connect-timeout", "15",
    "--retry", "10",
    "--retry-delay", "20",
    "--retry-connrefused",
    "--retry-all-errors",
    "--speed-limit", "1024",
    "--speed-time", "60",
    URL,
    "-o", TMP_FILE
]

try:
    subprocess.run(cmd, check=True)
except subprocess.CalledProcessError as e:
    if os.path.exists(TMP_FILE):
        os.remove(TMP_FILE)
    print(f"Error downloading NDW traffic signs: {e}", file=sys.stderr)
    sys.exit(1)

if not os.path.exists(TMP_FILE) or os.path.getsize(TMP_FILE) <= 1024 * 1024:
    if os.path.exists(TMP_FILE):
        os.remove(TMP_FILE)
    print(f"Downloaded {TMP_FILE} is missing or too small.", file=sys.stderr)
    sys.exit(1)

os.replace(TMP_FILE, JSON_FILE)
print(f"✓ {JSON_FILE} ({os.path.getsize(JSON_FILE)/1e6:.1f} MB)")
