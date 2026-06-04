from pathlib import Path

# Snapping Tolerances (in meters)
# Used in snap_c9_to_roads.py
PRIMARY_TOL = 2.0
FALLBACK_TOL = 60.0

# BRouter Configuration
# Used in build_brom_segments.py
BROUTER_VERSION = "brouter-1.7.8-all.jar"
DOCKER_BROUTER_PATH = Path("/opt/brouter")
