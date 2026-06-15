from pathlib import Path

# Snapping Tolerances (in meters)
# Used in snap_c9_to_roads.py
PRIMARY_TOL = 2.0
FALLBACK_TOL = 60.0

# BRouter Configuration
# Used in build_brom_segments.py
BROUTER_VERSION = "brouter-1.7.8-all.jar"
DOCKER_BROUTER_PATH = Path("/opt/brouter")

# ponytail: deduplicated from snap_c9_to_roads.py and tag_c9_roads.py
def find_osm_id_field(gdf):
    return next((f for f in ('osm_id', 'id', 'OSM_ID') if f in gdf.columns), None)
