from pathlib import Path

# Snapping Tolerances (in meters)
# Used in snap_c9_to_roads.py
PRIMARY_TOL = 2.0
FALLBACK_TOL = 60.0


# Finds the OSM ID field name dynamically from a GeoDataFrame
def find_osm_id_field(gdf):
    return next((f for f in ('osm_id', 'id', 'OSM_ID') if f in gdf.columns), None)
