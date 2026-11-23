#!/usr/bin/env python3
import subprocess
import os
import sys

URL = "https://download.geofabrik.de/europe/netherlands-latest.osm.pbf"
PBF_FILE = "nl_map.osm.pbf"
TMP_FILE = f"{PBF_FILE}.tmp"

if os.path.exists(PBF_FILE) and os.path.getsize(PBF_FILE) > 1024 * 1024:
    print(f"File {PBF_FILE} already exists. Skipping download.")
    sys.exit(0)

if os.path.exists(TMP_FILE):
    os.remove(TMP_FILE)

print("Fetching Netherlands OSM...")
cmd = [
    "curl", "-fL",
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
    print(f"Error downloading Netherlands OSM: {e}", file=sys.stderr)
    sys.exit(1)

if not os.path.exists(TMP_FILE) or os.path.getsize(TMP_FILE) <= 1024 * 1024:
    if os.path.exists(TMP_FILE):
        os.remove(TMP_FILE)
    print(f"Downloaded {TMP_FILE} is missing or too small.", file=sys.stderr)
    sys.exit(1)

os.replace(TMP_FILE, PBF_FILE)
print(f"✓ {PBF_FILE} ({os.path.getsize(PBF_FILE)/1e6:.1f} MB)")
