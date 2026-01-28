#!/usr/bin/env python3
import os
import zipfile
from pathlib import Path

def create_osmand_deploy_package():
    dist_dir = Path("dist")
    dist_dir.mkdir(exist_ok=True)
    
    zip_path = dist_dir / "brombrom_osmand_deploy.zip"
    
    # Path mappings for automated extraction
    # Android: OsmAnd expects files under Android/data/net.osmand/files/
    # BRouter: Android/media/btools.routingapp/brouter/
    
    OSMAND_BASE = "Android/data/net.osmand/files"
    BROUTER_BASE = "Android/media/btools.routingapp/brouter"
    
    files_to_pack = []

    # 1. BRouter Profile
    is_debug = os.environ.get("DEBUG") == "true"

    if is_debug:
        if Path("config/brommobiel.brf").exists():
            files_to_pack.append(("config/brommobiel.brf", f"{BROUTER_BASE}/profiles2/brommobiel.brf"))
        
        # 2. BRouter Segments (.rd5)
        segments_dir = Path("segments4")
        for rd5 in segments_dir.glob("*.rd5"):
            files_to_pack.append((str(rd5), f"{BROUTER_BASE}/segments4/{rd5.name}"))
    else:
        print("Skipping BRouter files (DEBUG != true)")

    # 3. OsmAnd Routing Config
    if Path("config/routing.xml").exists():
        files_to_pack.append(("config/routing.xml", f"{OSMAND_BASE}/routing/routing.xml"))

    # 4. OsmAnd Map (.obf)
    omc_dir = Path("OsmAndMapCreator")
    # We specifically look for our renamed map first
    target_obf = omc_dir / "NL_BromBrom_tagged.obf"
    if target_obf.exists():
        files_to_pack.append((str(target_obf), f"{OSMAND_BASE}/NL_BromBrom_tagged.obf"))
    else:
        # Fallback to any .obf for robustness, but rename it in the archive
        for obf in omc_dir.glob("*.obf"):
            files_to_pack.append((str(obf), f"{OSMAND_BASE}/NL_BromBrom_tagged.obf"))
            break

    print(f"Creating {zip_path}...")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for src, arcname in files_to_pack:
            if os.path.exists(src):
                print(f"  Adding {src} -> {arcname}")
                zf.write(src, arcname)
            else:
                print(f"Warning: {src} missing, skipping")

    print("✓ OsmAnd Deploy Package created")

if __name__ == "__main__":
    create_osmand_deploy_package()
