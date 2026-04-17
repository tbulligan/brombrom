#!/usr/bin/env python3
import os
import zipfile
from pathlib import Path

import json

def create_osmand_deploy_package():
    import shutil
    dist_dir = Path("dist")
    
    # Clean up and recreate dist folder
    if dist_dir.exists():
        shutil.rmtree(dist_dir)
    dist_dir.mkdir(exist_ok=True)
    
    is_debug = os.environ.get("DEBUG") == "true"
    
    # Paths to source files
    routing_src = Path("config/routing.xml")
    omc_dir = Path("OsmAndMapCreator")
    map_src = omc_dir / "NL_BromBrom_tagged.obf"
    
    # 1. We will create the OSF zip archive directly
    osf_path = dist_dir / "BromBrom.osf"
    
    # Define the OsmAnd items.json manifest
    items_manifest = {
        "version": 1,
        "items": [
            {
                "type": "PLUGIN",
                "pluginId": "com.brombrom.custom",
                "name": { "": "BromBrom Microcar Data" },
                "description": { "": "Map restrictions and routing configuration for L6e." }
            }
        ]
    }
    
    print(f"Building {osf_path} package...")
    
    with zipfile.ZipFile(osf_path, 'w', zipfile.ZIP_DEFLATED) as osf_zip:
        # Add Routing
        if routing_src.exists():
            osf_zip.write(routing_src, "routing.xml")
            items_manifest["items"].append({
                "type": "FILE",
                "pluginId": "com.brombrom.custom",
                "subtype": "ROUTING",
                "path": "routing.xml"
            })
            print(f"  Added routing.xml")
        else:
            print("  Warning: routing.xml not found")

        # Add Map Data
        if map_src.exists():
            osf_zip.write(map_src, "NL_BromBrom_tagged.obf")
            items_manifest["items"].append({
                "type": "FILE",
                "pluginId": "com.brombrom.custom",
                "subtype": "MAP",
                "path": "NL_BromBrom_tagged.obf"
            })
            print(f"  Added NL_BromBrom_tagged.obf")
        else:
             print("  Warning: Map .obf not found")
             
        # Optional Debug contents
        if is_debug:
            brf_src = Path("config/brommobiel.brf")
            if brf_src.exists():
                osf_zip.write(brf_src, "brommobiel.brf")
                items_manifest["items"].append({
                    "type": "FILE",
                    "pluginId": "com.brombrom.custom",
                    "subtype": "ROUTING",
                    "path": "brommobiel.brf"
                })
                print(f"  Added Debug config/brommobiel.brf")

        # Write the manifest into the zip
        osf_zip.writestr("items.json", json.dumps(items_manifest, indent=2))
        print("  Added items.json manifest")
        
    print("✓ Deployment package ready: dist/BromBrom.osf")

if __name__ == "__main__":
    create_osmand_deploy_package()
