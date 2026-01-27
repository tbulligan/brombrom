#!/usr/bin/env python
import os
import zipfile
from pathlib import Path

def create_android_deploy_package():
    dist_dir = Path("dist")
    dist_dir.mkdir(exist_ok=True)
    
    zip_path = dist_dir / "brombrom_android_deploy.zip"
    
    # Android Paths as specified by USER:
    # OsmAnd: Android/data/net.osmand/files/
    # BRouter: Android/media/btools.routingapp/brouter/
    
    OSMAND_BASE = "Android/data/net.osmand/files"
    BROUTER_BASE = "Android/media/btools.routingapp/brouter"
    
    files_to_pack = []

    # 1. BRouter Profile
    if Path("config/brommobiel.brf").exists():
        files_to_pack.append(("config/brommobiel.brf", f"{BROUTER_BASE}/profiles2/brommobiel.brf"))
    
    # 2. BRouter Segments (.rd5)
    segments_dir = Path("segments4")
    for rd5 in segments_dir.glob("*.rd5"):
        files_to_pack.append((str(rd5), f"{BROUTER_BASE}/segments4/{rd5.name}"))

    # 3. OsmAnd Routing Config
    if Path("config/routing.xml").exists():
        files_to_pack.append(("config/routing.xml", f"{OSMAND_BASE}/routing/routing.xml"))

    # 4. OsmAnd Map (.obf)
    omc_dir = Path("OsmAndMapCreator")
    for obf in omc_dir.glob("*.obf"):
        files_to_pack.append((str(obf), f"{OSMAND_BASE}/{obf.name}"))

    # 5. README
    if Path("README_UNIFIED.txt").exists():
        files_to_pack.append(("README_UNIFIED.txt", "README_INSTALL.txt"))

    print(f"Creating {zip_path}...")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for src, arcname in files_to_pack:
            if os.path.exists(src):
                print(f"  Adding {src} -> {arcname}")
                zf.write(src, arcname)
            else:
                print(f"Warning: {src} missing, skipping")

    print("✓ Android Deploy Package created")

if __name__ == "__main__":
    create_android_deploy_package()
