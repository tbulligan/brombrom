#!/usr/bin/env python3
import math
import geopandas as gpd
import pandas as pd
import json
import os
from shapely.geometry import LineString

try:
    import build_config as config
except ImportError:
    from scripts import build_config as config

PRIMARY_TOL = config.PRIMARY_TOL
FALLBACK_TOL = config.FALLBACK_TOL

import re

def has_microcar_exemption(row):
    """
    Check textSigns for 'brommobielen' exemptions using robust semantic logic.
    Returns True ONLY if an explicit exemption is found.
    """
    texts = row.get('textSigns', '')
    if pd.isna(texts) or not texts:
        return False
    
    try:
        # Normalize text: stringify, lower, and remove brackets/noise
        if not isinstance(texts, str):
            texts = str(texts)
        texts = texts.lower()
        
        # 1. Positive Exemption Context (Must have one)
        # Covers: 'uitgezonderd', 'm.u.v.', 'toegestaan', 'vrijgesteld', etc.
        pos_pattern = r'uitgezonderd|m\.u\.v\.|toegestaan|vrijgesteld|behalve|uitz|uitgez|muv'
        
        # 2. Vehicle Keywords (Must have one)
        # Covers: 'brommobiel', 'brommo', 'ob65' (official code), '45km', and common typos like 'brommoblelen'
        veh_pattern = r'bromm[oa][a-z]*|ob65|45\s?km'
        
        # 3. Negative Guards (Must NOT have)
        # Covers: 'geen', 'verboden', 'ook voor' (prohibition reinforcement)
        neg_pattern = r'geen|verboden|ook voor'
        
        # Check logic: (Positive AND Vehicle) AND NOT Negative
        has_pos = re.search(pos_pattern, texts) is not None
        has_veh = re.search(veh_pattern, texts) is not None
        has_neg = re.search(neg_pattern, texts) is not None
        
        # Special case: 'ob65' is an official sign code for exemption, treat as safe if present
        if 'ob65' in texts:
            return True

        return has_pos and has_veh and not has_neg

    except Exception:
        return False

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

def get_geometric_side(point, line_geom, projected_dist):
    """Determine if point is Left (L) or Right (R) of the line at projection"""
    # Sample a small segment around the projection
    p1 = line_geom.interpolate(projected_dist)
    # Look slightly ahead
    p2_dist = min(projected_dist + 1.0, line_geom.length)
    p2 = line_geom.interpolate(p2_dist)
    
    # If at end, look back
    if p1.equals(p2):
        p1 = line_geom.interpolate(max(projected_dist - 1.0, 0))
    
    dx = p2.x - p1.x
    dy = p2.y - p1.y
    
    # Vector from p1 to Point
    vx = point.x - p1.x
    vy = point.y - p1.y
    
    # Cross product (2D)
    cp = dx * vy - dy * vx
    
    if cp > 0.01: return 'L'
    if cp < -0.01: return 'R'
    return None

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
    if point is None or point.is_empty:
        return None, None
        
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

    # If still no bearing, pure distance ONLY if we also lack side info
    # This allows signs with Side='R' but Bearing=NaN to use the smart logic below
    side = str(row.get('side', '')).upper()
    has_side = side in ['L', 'R']
    
    if pd.isna(bearing) and not has_side:
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
        
        # Handle missing bearing gracefully
        if pd.isna(bearing):
            angle_diff = 0.0 # No angular penalty if we don't know the sign's angle
        else:
            angle_diff = min(abs(bearing - seg_bearing), 360 - abs(bearing - seg_bearing))
        
        # Side Matching Logic
        side_penalty = 0.0
        row_side = str(row.get('side', '')).upper()
        if row_side in ['L', 'R']:
            geom_side = get_geometric_side(point, line, proj_dist)
            
            # Check OneWay status (accessing row from roads_gdf using iloc)
            # We assume indices align with roads_geoms, which they do
            tags = str(roads_gdf.iloc[idx].get('other_tags', ''))
            is_oneway = '"oneway"=>"yes"' in tags or '"junction"=>"roundabout"' in tags or '"highway"=>"motorway"' in tags

            if geom_side == row_side:
                side_penalty = -2.0 # Bonus for matching side
            # No penalty for mismatch: rely on Angle (for opposing) and Bonus (for parallel)
            # This handles 'Breukelerwaard' where side data conflicts with OneWay geometry
            else:
                side_penalty = 0.0
        
        dist = proj_pt.distance(point)
        # Score formulation: Distance is king, but orientation/side refine it.
        score = dist * 0.7 + angle_diff * 0.03 + side_penalty

        if score < best_score:
            best_score = score
            best_idx = roads_gdf.index[idx] # Label index
            best_snap_pt = proj_pt

    return best_idx, best_snap_pt

def main():
    force_rebuild = os.environ.get("FORCE_REBUILD") == "true"
    debug_mode = os.environ.get("DEBUG") == "true"
    debug_missing = debug_mode and not os.path.exists("debug_snaps.gpkg")

    if os.path.exists("nl_roads_brom.gpkg") and not force_rebuild and not debug_missing:
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
        "motorway_link": 0,
        "trunk": 1,
        "trunk_link": 1,
        "primary": 1,
        "primary_link": 1,
        "secondary": 2,
        "secondary_link": 2,
        "tertiary": 3,
        "tertiary_link": 3,
        "residential": 4,
        "unclassified": 4
    }
    roads_gdf["priority"] = roads_gdf["highway"].map(highway_priority).fillna(99)
    valid_indices = roads_gdf[roads_gdf["priority"] < 10].index
    
    # Filter out snaps to invalid road types
    c9_gdf.loc[~c9_gdf["road_index"].isin(valid_indices), "road_index"] = None

    # Save Debug Line Layer (Visual Debugging)
    if os.environ.get("DEBUG") == "true":
        debug_links = []
        valid_snaps = c9_gdf.dropna(subset=['road_index', 'snap_point'])
        for _, row in valid_snaps.iterrows():
            debug_links.append(LineString([row.geometry, row['snap_point']]))
        
        if debug_links:
            debug_gdf = gpd.GeoDataFrame(geometry=debug_links, crs=c9_gdf.crs)
            debug_gdf.to_file("debug_snaps.gpkg", driver="GPKG")
            print(f"Saved {len(debug_gdf)} snap debug lines to debug_snaps.gpkg")
    else:
        print("Skipping debug_snaps.gpkg (DEBUG != true)")

    # Exemption filter
    exemption_mask = c9_gdf.apply(has_microcar_exemption, axis=1)
    exempt = c9_gdf[exemption_mask]
    print(f"Exemptions: {len(exempt)}")
    if len(exempt) > 0:
        exempt.to_file("c9_exemptions.gpkg", driver="GPKG", overwrite=True)

    c9_gdf = c9_gdf[~exemption_mask]
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
