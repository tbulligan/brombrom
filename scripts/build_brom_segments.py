#!/usr/bin/env python3
# build_brom_segments.py
# Implements the full BRouter map creation pipeline
import subprocess
import shutil
import os
from pathlib import Path

# Define paths relative to Project Root (parent of 'scripts')
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent

PBF_IN = PROJECT_ROOT / "nl_brom_tagged.osm.pbf"
SEG_OUT_DIR = PROJECT_ROOT / "segments4"
SRTM_DIR = PROJECT_ROOT / "srtm"
TEMP_DIR = PROJECT_ROOT / "temp_map_build"

# Paths to BRouter assets
# Check /opt/brouter (Docker isolation) first, then fallback to local
OPT_BROUTER = Path("/opt/brouter")
if OPT_BROUTER.exists():
    BROUTER_JAR = OPT_BROUTER / "brouter-server/build/libs/brouter-1.7.8-all.jar"
    PROFILES_DIR = OPT_BROUTER / "misc/profiles2"
else:
    BROUTER_ROOT = PROJECT_ROOT.parent / "brouter"
    BUNDLED_LIB = PROJECT_ROOT / "libs" / "brouter-1.7.8-all.jar"
    BUNDLED_PROFILES = PROJECT_ROOT / "profiles"
    
    if BUNDLED_LIB.exists():
        BROUTER_JAR = BUNDLED_LIB
        PROFILES_DIR = BUNDLED_PROFILES
    else:
        BROUTER_JAR = BROUTER_ROOT / "brouter-server" / "build" / "libs" / "brouter-1.7.8-all.jar"
        PROFILES_DIR = BROUTER_ROOT / "misc" / "profiles2"

LOOKUPS = PROFILES_DIR / "lookups.dat"
ALL_BRF = PROFILES_DIR / "all.brf"
BROMMOBIEL_BRF = PROJECT_ROOT / "config" / "brommobiel.brf"  # Use config path
TREKKING_BRF = PROFILES_DIR / "trekking.brf"
SOFTACCESS_BRF = PROFILES_DIR / "softaccess.brf"

def run_java(class_name, args, jvm_args=None):
    if jvm_args is None:
        jvm_args = ["-Xmx4G", "-Xms1G"]
    
    cmd = ["java"] + jvm_args + ["-cp", str(BROUTER_JAR), class_name] + [str(a) for a in args]
    print(f"Running {class_name}...")
    subprocess.run(cmd, check=True)

def build():
    if not PBF_IN.exists():
        print(f"Error: {PBF_IN} missing")
        exit(1)
    
    # Skip if output already exists
    if SEG_OUT_DIR.exists() and any(SEG_OUT_DIR.glob("*.rd5")):
        print(f"BRouter segments already exist in {SEG_OUT_DIR}. Skipping.")
        return

    if not BROUTER_JAR.exists():
        print(f"Error: BRouter JAR not found at {BROUTER_JAR}")
        exit(1)

    # Clean and create dirs
    if TEMP_DIR.exists():
        shutil.rmtree(TEMP_DIR)
    TEMP_DIR.mkdir()
    
    if SEG_OUT_DIR.exists():
        shutil.rmtree(SEG_OUT_DIR)
    SEG_OUT_DIR.mkdir()
    
    SRTM_DIR.mkdir(exist_ok=True) # Ensure it exists, even if empty

    cwd_original = os.getcwd()
    cwd_original = os.getcwd()
    os.chdir(TEMP_DIR)
    try:
        # 1. OsmCutter
        if not os.path.exists("nodetiles"):
            os.mkdir("nodetiles")
            run_java("btools.mapcreator.OsmCutter", 
                    [LOOKUPS, "nodetiles", "ways.dat", "relations.dat", "restrictions.dat", ALL_BRF, PBF_IN],
                    jvm_args=["-Xmx4G", "-DavoidMapPolling=true"])

        # Prepare nodetiles with all extensions just in case
        processed_stems = set()
        for f in Path("nodetiles").glob("*.*tl*"):
            base = f.stem
            if base in processed_stems:
                continue
            processed_stems.add(base)

            for ext in [".ntl", ".tls", ".tlf"]:
                target = f.parent / (base + ext)
                if not target.exists():
                    shutil.copy(str(f), str(target))

        # 2. NodeFilter
        if not os.path.exists("ftiles"):
            os.mkdir("ftiles")
            run_java("btools.mapcreator.NodeFilter",
                    ["nodetiles", "ways.dat", "ftiles"],
                    jvm_args=["-Xmx4G", "-Ddeletetmpfiles=false", "-DuseDenseMaps=true"])

        # Prepare ftiles with all extensions
        processed_stems = set()
        for f in Path("ftiles").glob("*.*tl*"):
            base = f.stem
            if base in processed_stems:
                continue
            processed_stems.add(base)

            for ext in [".ntl", ".tls", ".tlf"]:
                target = f.parent / (base + ext)
                if not target.exists():
                    shutil.copy(str(f), str(target))

        # 3. RelationMerger
        if not os.path.exists("ways2.dat"):
            run_java("btools.mapcreator.RelationMerger",
                    ["ways.dat", "ways2.dat", "relations.dat", LOOKUPS, TREKKING_BRF, SOFTACCESS_BRF],
                    jvm_args=["-Xmx4G", "-Ddeletetmpfiles=false", "-DuseDenseMaps=true"])

        # 4. WayCutter
        if not os.path.exists("waytiles"):
            os.mkdir("waytiles")
            run_java("btools.mapcreator.WayCutter",
                    ["ftiles", "ways2.dat", "waytiles"],
                    jvm_args=["-Xmx4G", "-Ddeletetmpfiles=false", "-DuseDenseMaps=true"])

        # 5. WayCutter5
        if not os.path.exists("waytiles55"):
            os.mkdir("waytiles55")
            run_java("btools.mapcreator.WayCutter5",
                    ["ftiles", "waytiles", "waytiles55", "bordernids.dat"],
                    jvm_args=["-Xmx4G", "-Ddeletetmpfiles=false", "-DuseDenseMaps=true"])

        # 6. NodeCutter
        if not os.path.exists("nodes55"):
            os.mkdir("nodes55")
            run_java("btools.mapcreator.NodeCutter",
                    ["ftiles", "nodes55"],
                    jvm_args=["-Xmx4G", "-Ddeletetmpfiles=false", "-DuseDenseMaps=true"])

        # 7. PosUnifier
        if not os.path.exists("unodes55"):
            os.mkdir("unodes55")
            run_java("btools.mapcreator.PosUnifier",
                    ["nodes55", "unodes55", "bordernids.dat", "bordernodes.dat", SRTM_DIR],
                    jvm_args=["-Xmx4G", "-Ddeletetmpfiles=false", "-DuseDenseMaps=true"])

        # 8. WayLinker
        # Use brommobiel.brf to EXCLUDE forbidden roads from routing graph
        # This prevents routing on them (no rerouting if accidentally on one)
        if not os.path.exists("segments"):
            os.mkdir("segments")
            run_java("btools.mapcreator.WayLinker",
                    ["unodes55", "waytiles55", "bordernodes.dat", "restrictions.dat", LOOKUPS, BROMMOBIEL_BRF, "segments", "rd5"],
                    jvm_args=["-Xmx4G", "-DuseDenseMaps=true"])

        # Move results
        print("Moving segments...")
        for seg in Path("segments").glob("*.rd5"):
            shutil.move(str(seg), str(SEG_OUT_DIR / seg.name))
            
        print(f"✓ Segments created in {SEG_OUT_DIR}")

    finally:
        os.chdir(cwd_original)
        # shutil.rmtree(TEMP_DIR) # Keep for debug if needed, or uncomment to clean

if __name__ == "__main__":
    build()
