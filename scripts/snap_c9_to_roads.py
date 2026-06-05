#!/usr/bin/env python3
import math
import geopandas as gpd
import pandas as pd
import json
import os
from shapely.geometry import LineString, box

try:
    import build_config as config
except ImportError:
    from scripts import build_config as config

PRIMARY_TOL = config.PRIMARY_TOL
FALLBACK_TOL = config.FALLBACK_TOL

import re

# 1. Positive Exemption Context (Must have one)
# Covers: 'uitgezonderd', 'm.u.v.', 'toegestaan', 'vrijgesteld', etc.
POS_EXEMPTION_PATTERN = re.compile(r'uitgezonderd|m\.u\.v\.|toegestaan|vrijgesteld|behalve|uitz|uitgez|muv')

# 2. Vehicle Keywords (Must have one)
# Covers: 'brommobiel', 'brommo', 'ob65' (official code), '45km', and common typos like 'brommoblelen'
VEHICLE_KEYWORDS_PATTERN = re.compile(r'bromm[oa][a-z]*|ob65|45\s?km')

# 3. Negative Guards (Must NOT have)
# Covers: 'geen', 'verboden', 'ook voor' (prohibition reinforcement)
NEGATIVE_GUARDS_PATTERN = re.compile(r'geen|verboden|ook voor')

# 4. Pre-warnings (Must NOT have)
# Matches NDW voorwaarschuwingsborden with type "VOOR"
PRE_WARNING_PATTERN = re.compile(r"['\"]type['\"]\s*:\s*['\"]VOOR['\"]", re.IGNORECASE)
def normalize_name(name):
    if not name or pd.isna(name):
        return ""
    name = str(name).lower().strip()
    name = re.sub(r'[^a-z0-9\s]', '', name)
    name = name.replace(" ", "")
    
    suffixes = ['straatweg', 'straat', 'weg', 'wei', 'dijk', 'dyk', 'laan', 'leane', 'singel', 'polder', 'pad', 'plein', 'steeg']
    suffixes.sort(key=len, reverse=True)
    for suffix in suffixes:
        if name.endswith(suffix) and len(name) > len(suffix):
            name = name[:-len(suffix)]
            break
    return name

def check_name_match(ndw_name, osm_name):
    if pd.isna(ndw_name) or not ndw_name or pd.isna(osm_name) or not osm_name:
        return True
    
    ndw_parts = re.split(r'[;/,-]', str(ndw_name))
    osm_parts = re.split(r'[;/,-]', str(osm_name))
    
    for ndw_p in ndw_parts:
        ndw_norm = normalize_name(ndw_p)
        if not ndw_norm:
            continue
        for osm_p in osm_parts:
            osm_norm = normalize_name(osm_p)
            if not osm_norm:
                continue
            if (ndw_norm == osm_norm) or (ndw_norm in osm_norm) or (osm_norm in ndw_norm):
                return True
    return False


# Global highway class priorities for snapping and filtering

HIGHWAY_PRIORITY = {
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


def is_pre_warning(row):
    """
    Check if a sign is a pre-warning (voorwaarschuwing) sign.
    Returns True if the sign's textSigns metadata designates it as a 'VOOR' warning.
    """
    texts = row.get('textSigns', '')
    if pd.isna(texts) or not texts:
        return False
    
    try:
        if not isinstance(texts, str):
            texts = str(texts)
        return PRE_WARNING_PATTERN.search(texts) is not None
    except Exception:
        return False

def get_road_speed(road_row):
    """Parse speed limit from road's other_tags."""
    if road_row is None:
        return None
    try:
        tags_str = road_row.get('other_tags') or ""
    except AttributeError:
        return None
    if not tags_str or pd.isna(tags_str):
        return None
    match = re.search(r'"maxspeed"=>"([^"]+)"', tags_str)
    if match:
        val = match.group(1).strip()
        if val in ['50', '30', '15', '5', 'walk', 'NL:15', 'NL:30', 'NL:50']:
            return 50.0
        try:
            return float(val)
        except ValueError:
            pass
    return None

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
        
        # Check logic: (Positive AND Vehicle) AND NOT Negative
        has_pos = POS_EXEMPTION_PATTERN.search(texts) is not None
        has_veh = VEHICLE_KEYWORDS_PATTERN.search(texts) is not None
        has_neg = NEGATIVE_GUARDS_PATTERN.search(texts) is not None
        
        # Special case: 'ob65' is an official sign code for exemption, treat as safe if present
        if 'ob65' in texts:
            return True

        return has_pos and has_veh and not has_neg

    except Exception:
        return False

def snap_c9_distance_only(row, roads_gdf, spatial_index, roads_geoms):
    # Original distance-based snap for fallback
    # Helper to calculate precise snap
    point = row.geometry
    ndw_name = row.get("roadName")
    
    def get_best_snap(candidates_indices):
        best_idx = None
        best_dist = float('inf')
        best_snap_pt = None
        
        for idx in candidates_indices:
            # geom = roads_gdf.geometry.iloc[idx] # unsafe if index mismatch
            # roads_geoms is a numpy array of geometries, aligned with iloc
            geom = roads_geoms[idx]
            dist = geom.distance(point)
            
            # Apply priority penalty to fallback snapping as well
            road_row = roads_gdf.iloc[idx]
            highway = str(road_row.get('highway', ''))
            priority = HIGHWAY_PRIORITY.get(highway, 99)
            if priority >= 4:
                priority_penalty = 8.0 / 0.7  # Convert score penalty to meters
            elif priority == 3:
                priority_penalty = 2.0 / 0.7
            else:
                priority_penalty = 0.0
                
            # Apply name mismatch penalty
            osm_name = road_row.get('name')
            name_matched = check_name_match(ndw_name, osm_name)
            name_penalty = 0.0 if name_matched else (30.0 / 0.7)
            
            effective_dist = dist + priority_penalty + name_penalty
            if effective_dist < best_dist:
                best_dist = effective_dist
                best_idx = roads_gdf.index[idx] # Get the label index
                
                # Calculate snap point
                proj = geom.project(point)
                best_snap_pt = geom.interpolate(proj)
        
        return best_idx, best_snap_pt

    primary = list(spatial_index.query(box(point.x - PRIMARY_TOL, point.y - PRIMARY_TOL, point.x + PRIMARY_TOL, point.y + PRIMARY_TOL)))
    if len(primary) > 0:
        return get_best_snap(primary)

    fallback = list(spatial_index.query(box(point.x - FALLBACK_TOL, point.y - FALLBACK_TOL, point.x + FALLBACK_TOL, point.y + FALLBACK_TOL)))
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
        return snap_c9_distance_only(row, roads_gdf, spatial_index, roads_geoms)

    candidates = list(spatial_index.query(box(point.x - FALLBACK_TOL, point.y - FALLBACK_TOL, point.x + FALLBACK_TOL, point.y + FALLBACK_TOL)))
    if len(candidates) == 0:
        return None, None

    best_idx, best_score = None, float("inf")
    best_snap_pt = None

    # Optimization: Access geometries directly
    candidate_geoms = roads_geoms[candidates]

    for idx, line in zip(candidates, candidate_geoms):
        road_row = roads_gdf.iloc[idx]
        proj_dist = line.project(point)
        proj_pt = line.interpolate(proj_dist)

        ahead_m = min(100.0, line.length / 2)
        ahead_frac = min(1.0, (proj_dist + ahead_m) / line.length)
        seg_end = line.interpolate(ahead_frac)

        seg_bearing = bearing_between(proj_pt, seg_end)
        
        # Check OneWay status
        tags = str(road_row.get('other_tags', ''))
        is_oneway = '"oneway"=>"yes"' in tags or '"junction"=>"roundabout"' in tags or '"highway"=>"motorway"' in tags

        # Handle missing bearing gracefully
        if pd.isna(bearing):
            angle_diff = 0.0 # No angular penalty if we don't know the sign's angle
        else:
            angle_diff = min(abs(bearing - seg_bearing), 360 - abs(bearing - seg_bearing))
            if not is_oneway:
                angle_diff_opp = min(abs(bearing - (seg_bearing + 180) % 360), 360 - abs(bearing - (seg_bearing + 180) % 360))
                angle_diff = min(angle_diff, angle_diff_opp)
        
        # Side Matching Logic
        side_penalty = 0.0
        row_side = str(row.get('side', '')).upper()
        if row_side in ['L', 'R']:
            geom_side = get_geometric_side(point, line, proj_dist)
            
            if geom_side == row_side:
                side_penalty = -2.0 # Bonus for matching side
            # No penalty for mismatch: rely on Angle (for opposing) and Bonus (for parallel)
            # This handles 'Breukelerwaard' where side data conflicts with OneWay geometry
            else:
                side_penalty = 0.0
        
        highway = str(road_row.get('highway', ''))
        priority = HIGHWAY_PRIORITY.get(highway, 99)
        if priority >= 4:
            priority_penalty = 8.0
        elif priority == 3:
            priority_penalty = 2.0
        else:
            priority_penalty = 0.0
            
        dist = proj_pt.distance(point)
        # Name match penalty
        ndw_name = row.get("roadName")
        osm_name = road_row.get("name")
        name_matched = check_name_match(ndw_name, osm_name)
        name_penalty = 0.0 if name_matched else 30.0

        # Score formulation: Distance is king, but orientation/side/priority refine it.
        # Use a larger weight (0.15) for angle difference to prevent perpendicular false snaps
        score = dist * 0.7 + angle_diff * 0.15 + side_penalty + priority_penalty + name_penalty

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
    
    # Filter out pre-warning (voorwaarschuwing) signs before snapping
    pre_warning_mask = c9_gdf.apply(is_pre_warning, axis=1)
    print(f"Filtering out {pre_warning_mask.sum()} pre-warning (VOOR) signs...")
    c9_gdf = c9_gdf[~pre_warning_mask]
    
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

    # Post-snapping pre-warning detection heuristic
    print("Running post-snapping pre-warning filter...")
    snapped_signs = c9_gdf.dropna(subset=['road_index']).copy()
    if not snapped_signs.empty:
        snapped_signs['norm_name'] = snapped_signs['roadName'].apply(normalize_name)
        
        speeds = []
        highways = []
        for r_idx in snapped_signs['road_index']:
            road_row = roads_gdf.loc[r_idx]
            speeds.append(get_road_speed(road_row))
            highways.append(road_row.get('highway', ''))
        snapped_signs['road_speed'] = speeds
        snapped_signs['road_highway'] = highways
        
        pre_warnings = set()
        for idx_A, row_A in snapped_signs.iterrows():
            speed_A = row_A['road_speed']
            highway_A = row_A['road_highway']
            
            # We only consider low-speed roads as potential pre-warnings
            is_low_speed = (speed_A is not None and speed_A <= 50) or highway_A in ['residential', 'living_street', 'service']
            if not is_low_speed:
                continue
                
            name_A = row_A['norm_name']
            bearing_A = row_A['bearing']
            if pd.isna(bearing_A):
                bearing_A = get_bearing_from_side(row_A['side'])
                
            geom_A = row_A.geometry
            
            for idx_B, row_B in snapped_signs.iterrows():
                if idx_A == idx_B:
                    continue
                    
                # Must be the same road
                if not name_A or name_A != row_B['norm_name']:
                    continue
                    
                # Must be within 1.5 km
                dist_m = geom_A.distance(row_B.geometry)
                if dist_m > 1500.0:
                    continue
                    
                # Must have similar bearings
                bearing_B = row_B['bearing']
                if pd.isna(bearing_B):
                    bearing_B = get_bearing_from_side(row_B['side'])
                    
                if bearing_A is not None and bearing_B is not None:
                    angle_diff = min(abs(bearing_A - bearing_B), 360 - abs(bearing_A - bearing_B))
                    if angle_diff > 45.0:
                        continue
                
                # Sign B must be on a high-speed road or trunk/motorway
                speed_B = row_B['road_speed']
                highway_B = row_B['road_highway']
                is_high_speed_B = (speed_B is not None and speed_B > 50) or highway_B in ['trunk', 'trunk_link', 'motorway', 'motorway_link']
                
                if is_high_speed_B:
                    # Sign A is a pre-warning!
                    pre_warnings.add(idx_A)
                    print(f"Identified Sign {row_A.get('id')} on '{row_A.get('roadName')}' as pre-warning for Sign {row_B.get('id')} (distance {dist_m:.1f}m).")
                    break
                    
        if pre_warnings:
            c9_gdf.loc[list(pre_warnings), "road_index"] = None
            print(f"Post-snapping pre-warning filter ignored {len(pre_warnings)} signs.")

    # Highway filtering using global priorities
    roads_gdf["priority"] = roads_gdf["highway"].map(HIGHWAY_PRIORITY).fillna(99)
    valid_indices = roads_gdf[roads_gdf["priority"] < 10].index
    
    # Filter out snaps to invalid road types
    c9_gdf.loc[~c9_gdf["road_index"].isin(valid_indices), "road_index"] = None

    # Save Debug Line Layer (Visual Debugging)
    if os.environ.get("DEBUG") == "true":
        valid_snaps = c9_gdf.dropna(subset=['road_index', 'snap_point'])
        debug_links = [
            LineString([g, s])
            for g, s in zip(valid_snaps.geometry, valid_snaps.snap_point)
        ]
        
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

    # Identify the OSM ID field name dynamically
    id_field = None
    for field in ['osm_id', 'id', 'OSM_ID']:
        if field in roads_gdf.columns:
            id_field = field
            break
    if id_field is None:
        raise ValueError("No OSM ID column found in roads_gdf")

    # Reproject snap points to WGS84 for lon/lat
    c9_gdf_wgs84 = c9_gdf.to_crs(epsg=4326)
    snap_geom_series = gpd.GeoSeries(c9_gdf["snap_point"], crs=28992).to_crs(epsg=4326)
    c9_gdf_wgs84["snap_lon"] = snap_geom_series.x
    c9_gdf_wgs84["snap_lat"] = snap_geom_series.y

    # Vectorized map to find the OSM ID for each snapped road (Task 1 optimization)
    c9_gdf_wgs84["osm_id"] = c9_gdf_wgs84["road_index"].map(roads_gdf[id_field])

    snaps_by_road = {}
    # Use fast itertuples iteration instead of iterrows
    for row in c9_gdf_wgs84.dropna(subset=["osm_id"]).itertuples():
        osm_id = int(row.osm_id)
        snap_info = {
            "lon": row.snap_lon,
            "lat": row.snap_lat,
            "bearing": row.bearing if not pd.isna(row.bearing) else None
        }
        if osm_id not in snaps_by_road:
            snaps_by_road[osm_id] = []
        snaps_by_road[osm_id].append(snap_info)

    # Store snap details in a JSON column
    forbidden_roads["c9_snaps"] = forbidden_roads[id_field].map(
        lambda oid: json.dumps(snaps_by_road.get(int(oid), []))
    )

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
