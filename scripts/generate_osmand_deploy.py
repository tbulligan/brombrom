#!/usr/bin/env python3
import os
import zipfile
from pathlib import Path

def create_osmand_deploy_package():
    import shutil
    dist_dir = Path("dist")
    
    # Clean up and recreate dist folder
    if dist_dir.exists():
        shutil.rmtree(dist_dir)
    dist_dir.mkdir(exist_ok=True)
    
    # Files to be staged for release
    files_to_copy = []

    # 1. BRouter Profile (if debug)
    is_debug = os.environ.get("DEBUG") == "true"
    if is_debug:
        if Path("config/brommobiel.brf").exists():
            files_to_copy.append(("config/brommobiel.brf", "brommobiel.brf"))
        
        # 2. BRouter Segments (.rd5)
        segments_dir = Path("segments4")
        for rd5 in segments_dir.glob("*.rd5"):
            files_to_copy.append((str(rd5), rd5.name))
    
    # 2. OsmAnd Routing Config
    if Path("config/routing.xml").exists():
        files_to_copy.append(("config/routing.xml", "routing.xml"))

    # 3. OsmAnd Map (.obf)
    omc_dir = Path("OsmAndMapCreator")
    target_obf = omc_dir / "NL_BromBrom_tagged.obf"
    if target_obf.exists():
        files_to_copy.append((str(target_obf), "NL_BromBrom_tagged.obf"))
    
    print(f"Staging files in {dist_dir}...")
    for src, dest_name in files_to_copy:
        if os.path.exists(src):
            print(f"  Copying {src} -> {dist_dir}/{dest_name}")
            shutil.copy2(src, dist_dir / dest_name)
        else:
            print(f"Warning: {src} missing, skipping")

    print("✓ Deployment files ready in dist/")

if __name__ == "__main__":
    create_osmand_deploy_package()
