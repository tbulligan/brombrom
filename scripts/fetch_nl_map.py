#!/usr/bin/env python3
import requests
from tqdm import tqdm
import os

URL = "https://download.geofabrik.de/europe/netherlands-latest.osm.pbf"
PBF_FILE = "nl_map.osm.pbf"

if os.path.exists(PBF_FILE) and os.path.getsize(PBF_FILE) > 1024 * 1024:
    print(f"File {PBF_FILE} already exists. Skipping download.")
    exit(0)

r = requests.get(URL, stream=True, timeout=30)
r.raise_for_status()

total_size = int(r.headers.get('content-length', 0))

print("Fetching Netherlands OSM...")
with open(PBF_FILE, "wb") as f, tqdm(
    desc="NL OSM", total=total_size, unit="B", unit_scale=True
) as pbar:
    for chunk in r.iter_content(chunk_size=1024 * 1024):
        f.write(chunk)
        pbar.update(len(chunk))

print(f"✓ {PBF_FILE} ({os.path.getsize(PBF_FILE)/1e6:.1f} MB)")
