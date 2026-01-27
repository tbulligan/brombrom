#!/usr/bin/env python3
import math
import geopandas as gpd
import pandas as pd
import json

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

if False: # Forced re-run disabled for now, relying on file check
    pass
import os
if os.path.exists("nl_roads_brom.gpkg"):
    print("nl_roads_brom.gpkg already exists. Skipping.")
    exit(0)

# Load and reproject to RD New (EPSG:28992) for accurate distances
c9_gdf = gpd.read_file("c9_ndw.gpkg").to_crs(epsg=28992)
roads_gdf = gpd.read_file("nl_roads.gpkg").to_crs(epsg=28992)

# Build spatial index
spatial_index = roads_gdf.sindex

PRIMARY_TOL = 2.0  # 2 m
FALLBACK_TOL = 5.0  # 5 m

def snap_c9_distance_only(point):
    # Original distance-based snap for fallback
    primary = spatial_index.query(point.buffer(PRIMARY_TOL))
    if len(primary) > 0:
        candidates = roads_gdf.iloc[primary]
        return candidates.distance(point).idxmin()

    fallback = spatial_index.query(point.buffer(FALLBACK_TOL))
    if len(fallback) > 0:
        candidates = roads_gdf.iloc[fallback]
        return candidates.distance(point).idxmin()

    return None

def bearing_between(p1, p2):
    dx, dy = p2.x - p1.x, p2.y - p1.y
    return (math.degrees(math.atan2(dy, dx)) + 360) % 360

def get_bearing_from_side(side):
    """NDW side windroos → degrees"""
    side_map = {
        'N': 0,
        'NNO': 22.5,
        'NO': 45,
        'ONO': 67.5,
        'O': 90,
        'OZO': 112.5,
        'ZO': 135,
        'ZZO': 157.5,
        'Z': 180,
        'ZZW': 202.5,  # fixed duplicate key: ZZ**W**
        'ZW': 225,
        'WZW': 247.5,
        'W': 270,
        'WNW': 292.5,
        'NW': 315,
        'NNW': 337.5
    }
    return side_map.get(str(side).upper(), None)

# optional: if you use side_count, initialize it
side_count = {"N": 0, "O": 0, "Z": 0, "W": 0}

def directional_snap(row, roads_gdf, spatial_index, tol=5.0):
    point = row.geometry
    bearing = row.get("bearing")

    # Fallback side → bearing
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
        return snap_c9_distance_only(point)

    candidates = spatial_index.query(point.buffer(tol))
    if len(candidates) == 0:
        return None

    best_idx, best_score = None, float("inf")
    for idx in candidates:
        road = roads_gdf.iloc[idx]
        line = road.geometry

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
            best_idx = idx

    return best_idx

# Apply directional snapping
c9_gdf["road_index"] = c9_gdf.apply(
    lambda row: directional_snap(row, roads_gdf, spatial_index),
    axis=1
)

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
c9_gdf["road_index"] = c9_gdf["road_index"].where(
    c9_gdf["road_index"].isin(valid_indices)
)

# Exemption filter
exempt = c9_gdf[c9_gdf.apply(has_microcar_exemption, axis=1)]
print(f"Exemptions: {len(exempt)}")
if len(exempt) > 0:
    exempt.to_file("c9_exemptions.gpkg", driver="GPKG", overwrite=True)

c9_gdf = c9_gdf[~c9_gdf.apply(has_microcar_exemption, axis=1)]
print(f"→ {len(c9_gdf)} C9s for tagging")

# Output forbidden roads
forbidden_roads = roads_gdf.loc[c9_gdf["road_index"].dropna().unique()].copy()
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

side_stats = c9_gdf['side'].value_counts()
print("NaN→side snaps:",
      (~c9_gdf['bearing'].isna() & c9_gdf['side'].isin(['N', 'O', 'Z', 'W'])).sum())
