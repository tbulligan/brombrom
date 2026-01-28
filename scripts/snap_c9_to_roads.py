#!/usr/bin/env python3
import math
import geopandas as gpd
import pandas as pd
import json
import os
from shapely.geometry import LineString

PRIMARY_TOL = 2.0  # 2 m
FALLBACK_TOL = 12.0  # 12 m (Increased from 5m to catch imprecise sign coordinates)

def has_microcar_exemption(row):
    """Check textSigns for 'brommobielen' exemptions"""
    texts = row.get('textSigns', '')
    if pd.isna(texts):
        return False
    try:
        if isinstance(texts, str):
            texts = json.loads(texts) if texts.startswith('[') else texts
        texts = str(texts).lower()
    except Exception:
        texts = str(texts).lower()
    return 'brommobielen' in texts

def snap_c9_distance_only(point, roads_gdf, spatial_index, roads_geoms):
    # Original distance-based snap for fallback
    # Helper to calculate precise snap
    def get_best_snap(candidates_indices):
        best_idx = None
        best_dist = float('inf')
        best_snap_pt = None
        
        for idx in candidates_indices:
            # geom = roads_gdf.geometry.iloc[idx] # unsafe if index mismatch
            # roads_geoms is a numpy array of geometries, aligned with iloc
            geom = roads_geoms[idx]
            dist = geom.distance(point)
            if dist < best_dist:
                best_dist = dist
                best_idx = roads_gdf.index[idx] # Get the label index
                
                # Calculate snap point
                proj = geom.project(point)
                best_snap_pt = geom.interpolate(proj)
        
        return best_idx, best_snap_pt

    primary = list(spatial_index.query(point.buffer(PRIMARY_TOL)))
    if len(primary) > 0:
        return get_best_snap(primary)

    fallback = list(spatial_index.query(point.buffer(FALLBACK_TOL)))
    if len(fallback) > 0:
        return get_best_snap(fallback)

    return None, None

def bearing_between(p1, p2):
    dx, dy = p2.x - p1.x, p2.y - p1.y
    return (math.degrees(math.atan2(dy, dx)) + 360) % 360

SIDE_MAP = {
    'N': 0, 'NNO': 22.5, 'NO': 45, 'ONO': 67.5,
    'O': 90, 'OZO': 112.5, 'ZO': 135, 'ZZO': 157.5,
    'Z': 180, 'ZZW': 202.5, 'ZW': 225, 'WZW': 247.5,
    'W': 270, 'WNW': 292.5, 'NW': 315, 'NNW': 337.5
}

def get_bearing_from_side(side):
    """NDW side windroos -> degrees"""
    return SIDE_MAP.get(str(side).upper(), None)

def directional_snap(row, roads_gdf, spatial_index, roads_geoms, side_count):
    point = row.geometry
    bearing = row.get("bearing")

    # Fallback side -> bearing
    if pd.isna(bearing) or bearing == 0.0:
        side_bearing = get_bearing_from_side(row.get('side'))
        if side_bearing is not None:
            bearing = side_bearing

    # Optional side stats
    side = str(row.get('side', '')).upper()
    if side in side_count:
        side_count[side] += 1

    # If still no bearing, pure distance
    if pd.isna(bearing):
        return snap_c9_distance_only(point, roads_gdf, spatial_index, roads_geoms)

    candidates = list(spatial_index.query(point.buffer(FALLBACK_TOL)))
    if len(candidates) == 0:
        return None, None

    best_idx, best_score = None, float("inf")
    best_snap_pt = None

    # Optimization: Access geometries directly
    candidate_geoms = roads_geoms[candidates]

    for idx, line in zip(candidates, candidate_geoms):
        proj_dist = line.project(point)
        proj_pt = line.interpolate(proj_dist)

        ahead_m = min(100.0, line.length / 2)
        ahead_frac = min(1.0, (proj_dist + ahead_m) / line.length)
        seg_end = line.interpolate(ahead_frac)

        seg_bearing = bearing_between(proj_pt, seg_end)
        angle_diff = min(abs(bearing - seg_bearing), 360 - abs(bearing - seg_bearing))

        dist = proj_pt.distance(point)
        score = dist * 0.7 + angle_diff * 0.03

        if score < best_score:
            best_score = score
            best_idx = roads_gdf.index[idx] # Label index
            best_snap_pt = proj_pt

    return best_idx, best_snap_pt

def main():
    if False: # Forced re-run disabled for now
        pass

    if os.path.exists("nl_roads_brom.gpkg") and not os.environ.get("FORCE_REBUILD"):
        print("nl_roads_brom.gpkg already exists. Skipping.")
        return

    # Load and reproject to RD New (EPSG:28992) for accurate distances
    c9_gdf = gpd.read_file("c9_ndw.gpkg").to_crs(epsg=28992)
    roads_gdf = gpd.read_file("nl_roads.gpkg").to_crs(epsg=28992)

    # Build spatial index
    spatial_index = roads_gdf.sindex

    # side_count initialization
    side_count = {"N": 0, "O": 0, "Z": 0, "W": 0}

    # Apply directional snapping
    roads_geoms = roads_gdf.geometry.values
    
    print(f"Snapping {len(c9_gdf)} signs with tolerance {FALLBACK_TOL}m...")
    
    # Run snapping and expand result into two columns
    snap_results = c9_gdf.apply(
        lambda row: directional_snap(row, roads_gdf, spatial_index, roads_geoms, side_count),
        axis=1,
        result_type='expand'
    )
    c9_gdf["road_index"] = snap_results[0]
    c9_gdf["snap_point"] = snap_results[1]

    print(f"Directionally snapped {c9_gdf['road_index'].notna().sum()}/{len(c9_gdf)} C9s")

    # Highway filtering
    highway_priority = {
        "motorway": 0,
        "trunk": 1,
        "primary": 1,
        "secondary": 2,
        "tertiary": 3,
        "residential": 4,
        "unclassified": 4
    }
    roads_gdf["priority"] = roads_gdf["highway"].map(highway_priority).fillna(99)
    valid_indices = roads_gdf[roads_gdf["priority"] < 10].index
    
    # Filter out snaps to invalid road types
    c9_gdf.loc[~c9_gdf["road_index"].isin(valid_indices), "road_index"] = None

    # Save Debug Line Layer (Visual Debugging)
    debug_links = []
    valid_snaps = c9_gdf.dropna(subset=['road_index', 'snap_point'])
    for _, row in valid_snaps.iterrows():
        debug_links.append(LineString([row.geometry, row['snap_point']]))
    
    if debug_links:
        debug_gdf = gpd.GeoDataFrame(geometry=debug_links, crs=c9_gdf.crs)
        debug_gdf.to_file("debug_snaps.gpkg", driver="GPKG")
        print(f"Saved {len(debug_gdf)} snap debug lines to debug_snaps.gpkg")

    # Exemption filter
    exempt = c9_gdf[c9_gdf.apply(has_microcar_exemption, axis=1)]
    print(f"Exemptions: {len(exempt)}")
    if len(exempt) > 0:
        exempt.to_file("c9_exemptions.gpkg", driver="GPKG", overwrite=True)

    c9_gdf = c9_gdf[~c9_gdf.apply(has_microcar_exemption, axis=1)]
    print(f"-> {len(c9_gdf)} C9s for tagging")

    # Output forbidden roads
    forbidden_ids = c9_gdf["road_index"].dropna().unique()
    forbidden_roads = roads_gdf.loc[forbidden_ids].copy()
    forbidden_roads["microcar"] = "no"
    forbidden_roads.to_crs(epsg=4326).to_file(
        "nl_roads_brom.gpkg",
        layer="brom_roads",
        driver="GPKG"
    )
    print(f"Flagged {len(forbidden_roads)} C9 roads")

    missed = c9_gdf[c9_gdf["road_index"].isna()]
    print(f"SNAP: {c9_gdf['road_index'].notna().sum():,} / {len(c9_gdf)} "
          f"({100*len(missed)/len(c9_gdf):.1f}% missed)")
    missed.to_file("missed_c9.gpkg", overwrite=True)

    # side_stats = c9_gdf['side'].value_counts()
    print("NaN->side snaps:",
          (~c9_gdf['bearing'].isna() & c9_gdf['side'].isin(['N', 'O', 'Z', 'W'])).sum())

if __name__ == "__main__":
    main()
