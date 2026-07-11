#!/usr/bin/env python3
import requests, os, gzip
from tqdm import tqdm

# NDW 'current-state' endpoint provides a full snapshot that regenerates every month.
URL = "https://data.ndw.nu/api/rest/static-road-data/traffic-signs/v4/current-state?rvv-code=C9"
JSON_FILE = "ndw_c9_current_state.json"

if os.path.exists(JSON_FILE) and os.path.getsize(JSON_FILE) > 1024 * 1024:
    print(f"File {JSON_FILE} already exists. Skipping download.")
    exit(0)

headers = {
    "Accept-Encoding": "gzip, deflate"
}

with requests.get(URL, headers=headers, stream=True, timeout=30) as r:
    r.raise_for_status()
    content_encoding = (r.headers.get("content-encoding") or "").lower()

    if "gzip" in content_encoding:
        print("→ Download mode: gzipped HTTP, streaming decompress to JSON")
        decompressor = gzip.GzipFile(fileobj=r.raw)

        with open(JSON_FILE, "wb") as out_f, tqdm(
            desc="NDW C9 (gz→json)", unit="B", unit_scale=True
        ) as pbar:
            while True:
                chunk = decompressor.read(8192)
                if not chunk:
                    break
                out_f.write(chunk)
                pbar.update(len(chunk))
    else:
        print("→ Download mode: plain JSON (no HTTP compression)")
        with open(JSON_FILE, "wb") as out_f, tqdm(
            desc="NDW C9 (json)", unit="B", unit_scale=True
        ) as pbar:
            for chunk in r.iter_content(chunk_size=8192):
                out_f.write(chunk)
                pbar.update(len(chunk))

print(f"✓ JSON size on disk: {os.path.getsize(JSON_FILE)/1e6:.1f} MB")
