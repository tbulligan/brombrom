import pytest
from shapely.geometry import Point, LineString
from scripts import snap_c9_to_roads

def test_exemption_logic():
    # Test normal exemption
    assert snap_c9_to_roads.has_microcar_exemption({'textSigns': 'uitgezonderd brommobielen'})
    assert snap_c9_to_roads.has_microcar_exemption({'textSigns': 'm.u.v. brommobiel'})

    # Test OCR typo (intentional support)
    assert snap_c9_to_roads.has_microcar_exemption({'textSigns': 'uitgezonderd brommoblelen'})

    # Test OB65 code
    assert snap_c9_to_roads.has_microcar_exemption({'textSigns': 'OB65'})
    
    # Test 45km
    assert snap_c9_to_roads.has_microcar_exemption({'textSigns': 'uitgezonderd 45km'})
    assert snap_c9_to_roads.has_microcar_exemption({'textSigns': 'bestemmingsverkeer en 45 km toegestaan'})

    # Test negative cases
    assert not snap_c9_to_roads.has_microcar_exemption({'textSigns': 'uitgezonderd fietsers'})
    assert not snap_c9_to_roads.has_microcar_exemption({'textSigns': 'vrachtverkeer'})
    assert not snap_c9_to_roads.has_microcar_exemption({'textSigns': ''})
    assert not snap_c9_to_roads.has_microcar_exemption({})

    # Test numpy array inputs
    import numpy as np
    assert snap_c9_to_roads.has_microcar_exemption({'textSigns': np.array(['uitgezonderd brommobielen'])})
    assert not snap_c9_to_roads.has_microcar_exemption({'textSigns': np.array([])})

    # Test explicit prohibitions (Negative Guards)
    assert not snap_c9_to_roads.has_microcar_exemption({'textSigns': 'Geldt ook voor brommobiel'})
    assert not snap_c9_to_roads.has_microcar_exemption({'textSigns': 'Dus geen brommobielen'})
    assert not snap_c9_to_roads.has_microcar_exemption({'textSigns': 'verboden voor brommobielen'})

    # Test missing positive context
    assert not snap_c9_to_roads.has_microcar_exemption({'textSigns': 'brommobielen'}) # Broadly 'brommobielen' with no context is unsafe

def test_bearing_calculation():
    # Current implementation uses Math Angle (0=East, 90=North)
    p1 = Point(0, 0)

    # East
    p2 = Point(1, 0)
    assert snap_c9_to_roads.bearing_between(p1, p2) == pytest.approx(0.0)

    # North
    p3 = Point(0, 1)
    assert snap_c9_to_roads.bearing_between(p1, p3) == pytest.approx(90.0)

    # West
    p4 = Point(-1, 0)
    assert snap_c9_to_roads.bearing_between(p1, p4) == pytest.approx(180.0)

    # South
    p5 = Point(0, -1)
    assert snap_c9_to_roads.bearing_between(p1, p5) == pytest.approx(270.0)

def test_geometric_side():
    # Vertical line going North (0,0) -> (0,10)
    line = LineString([(0, 0), (0, 10)])

    # Point to the Left (-x)
    p_left = Point(-2, 5)
    assert snap_c9_to_roads.get_geometric_side(p_left, line, 5.0) == 'L'

    # Point to the Right (+x)
    p_right = Point(2, 5)
    assert snap_c9_to_roads.get_geometric_side(p_right, line, 5.0) == 'R'

    # Point on line (approx)
    p_on = Point(0, 5)
    assert snap_c9_to_roads.get_geometric_side(p_on, line, 5.0) is None

def test_distance_meters():
    from scripts import tag_c9_roads
    # Distance between same points should be 0
    assert tag_c9_roads.distance_meters(5.0, 52.0, 5.0, 52.0) == pytest.approx(0.0)
    # Approximate distance between (5.0, 52.0) and (5.01, 52.0)
    assert tag_c9_roads.distance_meters(5.0, 52.0, 5.01, 52.0) == pytest.approx(685.35, abs=5.0)

def test_pre_warning_logic():
    # Test positive cases (pre-warnings)
    assert snap_c9_to_roads.is_pre_warning({'textSigns': "[{'type': 'VOOR', 'text': '100 m'}]"})
    assert snap_c9_to_roads.is_pre_warning({'textSigns': "[{'type': 'VOOR', 'text': 'na 500 m'}]"})
    assert snap_c9_to_roads.is_pre_warning({'textSigns': '[{"type": "VOOR", "text": "150 m"}]'})

    # Test negative cases (regular signs or exemptions)
    assert not snap_c9_to_roads.is_pre_warning({'textSigns': "[{'type': 'UIT', 'text': 'Uitgezonderd brommobielen'}]"})
    assert not snap_c9_to_roads.is_pre_warning({'textSigns': '[]'})
    assert not snap_c9_to_roads.is_pre_warning({'textSigns': ''})
    assert not snap_c9_to_roads.is_pre_warning({})

def test_name_matching_logic():
    # Test normalization
    assert snap_c9_to_roads.normalize_name('Hegedyk') == 'hege'
    assert snap_c9_to_roads.normalize_name('Westergoawei') == 'westergoa'
    assert snap_c9_to_roads.normalize_name('Groningerstraatweg') == 'groninger'
    assert snap_c9_to_roads.normalize_name('Blitsaerderleane') == 'blitsaerder'
    
    # Test matching
    assert snap_c9_to_roads.check_name_match('Hegedyk', 'Hegedyk')
    assert not snap_c9_to_roads.check_name_match('Hegedyk', 'Westergoawei')
    assert not snap_c9_to_roads.check_name_match('Tolhûswei', 'Blitsaerderleane')
    
    # Missing names should match (no penalty)
    assert snap_c9_to_roads.check_name_match('Tolhûswei', None)
    assert snap_c9_to_roads.check_name_match(None, 'Hegedyk')
    
    # Multi-name / composite roads
    assert snap_c9_to_roads.check_name_match('Groningerstraatweg;N355', 'Groningerstraatweg')
    assert snap_c9_to_roads.check_name_match('Westergoawei', 'Rijksweg N313 / Westergoawei')

def test_get_road_speed():
    # Test valid speed parsing
    assert snap_c9_to_roads.get_road_speed({'other_tags': '"maxspeed"=>"50"'}) == 50.0
    assert snap_c9_to_roads.get_road_speed({'other_tags': '"maxspeed"=>"30"'}) == 50.0
    assert snap_c9_to_roads.get_road_speed({'other_tags': '"maxspeed"=>"walk"'}) == 50.0
    assert snap_c9_to_roads.get_road_speed({'other_tags': '"maxspeed"=>"80"'}) == 80.0
    assert snap_c9_to_roads.get_road_speed({'other_tags': '"maxspeed"=>"NL:30"'}) == 50.0

    # Test invalid / missing speed
    assert snap_c9_to_roads.get_road_speed({'other_tags': '"surface"=>"asphalt"'}) is None
    assert snap_c9_to_roads.get_road_speed(None) is None
    assert snap_c9_to_roads.get_road_speed({}) is None


def test_road_filtering():
    import pandas as pd
    # Mock roads data
    df = pd.DataFrame([
        # Minor roads (priority >= 4)
        {"highway": "residential", "other_tags": None, "junction": None},
        {"highway": "unclassified", "other_tags": None, "junction": None},
        {"highway": "service", "other_tags": None, "junction": None},
        {"highway": "living_street", "other_tags": None, "junction": None},
        
        # Roundabouts
        {"highway": "primary", "other_tags": '"junction"=>"roundabout"', "junction": None},
        {"highway": "secondary", "other_tags": None, "junction": "roundabout"},
        {"highway": "roundabout", "other_tags": None, "junction": None},
        
        # Valid roads
        {"highway": "primary", "other_tags": None, "junction": None},
        {"highway": "secondary", "other_tags": None, "junction": None},
        {"highway": "tertiary", "other_tags": None, "junction": None},
    ])
    
    # Priority mapping
    priority_series = df["highway"].map(snap_c9_to_roads.HIGHWAY_PRIORITY).fillna(99)
    is_minor = priority_series >= 4
    
    # Roundabout checks
    other_tags_series = df['other_tags'].fillna("").astype(str)
    highway_series = df['highway'].fillna("").astype(str)
    junction_series = df['junction'].fillna("").astype(str)
    
    is_roundabout = (
        other_tags_series.str.contains('"junction"=>"roundabout"', regex=False) |
        highway_series.str.contains('roundabout', regex=False) |
        (junction_series == 'roundabout')
    )
    
    # Assertions
    # First 4 should be classified as minor (priority >= 4)
    assert list(is_minor[:4]) == [True, True, True, True]
    # Rest should not be minor except highway=roundabout which maps to priority 99
    assert list(is_minor[4:]) == [False, False, True, False, False, False]
    
    # Index 4, 5, 6 should be roundabouts
    assert list(is_roundabout[4:7]) == [True, True, True]
    # Rest should not be roundabouts
    assert list(is_roundabout[:4]) == [False, False, False, False]
    assert list(is_roundabout[7:]) == [False, False, False]


def test_intersection_bonus():
    import geopandas as gpd
    import pandas as pd
    from shapely.geometry import Point, LineString
    
    # Sign on a side street (De Dors) approaching primary highway (Kolkweg)
    # Coords: sign is at (0, 0), facing North (bearing 90)
    sign = pd.Series({
        'roadName': 'De Dors',
        'bearing': 0.0,
        'side': 'R',
        'geometry': Point(0, 0)
    })
    
    # Roads in filtered database (bidirectional — no oneway tag)
    # Road 1: Kolkweg (primary, priority 1, heading North) -> 10m away
    # Road 2: Zuideinde (tertiary, priority 3, heading North) -> 8m away
    roads = gpd.GeoDataFrame([
        {
            'osm_id': 101, 'name': 'Kolkweg', 'highway': 'primary', 'priority': 1,
            'geometry': LineString([(10, -50), (10, 50)]), 'other_tags': ''
        },
        {
            'osm_id': 102, 'name': 'Zuideinde', 'highway': 'tertiary', 'priority': 3,
            'geometry': LineString([(-8, -50), (-8, 50)]), 'other_tags': ''
        }
    ], crs="EPSG:28992")
    
    # Run directional snap
    spatial_index = roads.sindex
    geoms = roads.geometry.values
    
    best_idx, snap_pt = snap_c9_to_roads.directional_snap(sign, roads, spatial_index, geoms, {})
    
    # Kolkweg (primary) should win due to the conditional warning bonus
    assert best_idx == 0
    assert roads.loc[best_idx]['name'] == 'Kolkweg'


def test_intersection_bonus_oneway_non_dual():
    """The Intersection Warning Bonus SHOULD fire for a lone one-way road.

    When a one-way primary is NOT part of a dual carriageway (no opposing
    carriageway within 20m), the bonus fires and the primary wins.
    """
    import geopandas as gpd
    import pandas as pd
    from shapely.geometry import Point, LineString

    sign = pd.Series({
        'roadName': 'Kerkstraat',
        'bearing': 0.0,
        'side': 'L',
        'geometry': Point(0, 0)
    })

    # One-way primary 30m east, bidirectional tertiary 8m west.
    # No opposing carriageway near the primary -> bonus fires -> primary wins.
    roads = gpd.GeoDataFrame([
        {
            'osm_id': 301, 'name': 'Daelderweg', 'highway': 'primary', 'priority': 1,
            'geometry': LineString([(30, 0), (30, 20)]),
            'other_tags': '"oneway"=>"yes"'
        },
        {
            'osm_id': 302, 'name': 'Zuideinde', 'highway': 'tertiary', 'priority': 3,
            'geometry': LineString([(-8, 0), (-8, 20)]),
            'other_tags': ''
        }
    ], crs="EPSG:28992")
    idx, _ = snap_c9_to_roads.directional_snap(sign, roads, roads.sindex, roads.geometry.values, {})
    assert roads.loc[idx]['name'] == 'Daelderweg', (
        "Lone one-way primary must win: no opposing carriageway detected"
    )


def test_intersection_bonus_blocked_for_dual_carriageway():
    """The Intersection Warning Bonus must NOT fire for dual carriageways.

    When two parallel one-way roads of similar class run in opposite directions
    within 20m (e.g. N298 Daelderweg), the bonus is blocked to prevent
    asymmetric microcar blocking.
    """
    import geopandas as gpd
    import pandas as pd
    from shapely.geometry import Point, LineString

    sign = pd.Series({
        'roadName': 'Kerkstraat',
        'bearing': 0.0,
        'side': 'L',
        'geometry': Point(0, 0)
    })

    # Dual carriageway: two one-way primaries 15m apart, opposing directions.
    # Bonus BLOCKED for primaries -> tertiary wins.
    # Scores:
    #   primary (east):  30*0.7 + 0*0.15 + 0 + 0 + 30 = 51.0
    #   tertiary (west):  8*0.7 + 0*0.15 + 0 + 2 + 30 = 37.6  <- wins
    roads = gpd.GeoDataFrame([
        {
            'osm_id': 501, 'name': 'Daelderweg', 'highway': 'primary', 'priority': 1,
            'geometry': LineString([(30, 0), (30, 20)]),    # northbound
            'other_tags': '"oneway"=>"yes"'
        },
        {
            'osm_id': 502, 'name': 'Daelderweg', 'highway': 'primary', 'priority': 1,
            'geometry': LineString([(45, 20), (45, 0)]),    # southbound, 15m away
            'other_tags': '"oneway"=>"yes"'
        },
        {
            'osm_id': 503, 'name': 'Zuideinde', 'highway': 'tertiary', 'priority': 3,
            'geometry': LineString([(-8, 0), (-8, 20)]),
            'other_tags': ''
        }
    ], crs="EPSG:28992")
    idx, _ = snap_c9_to_roads.directional_snap(sign, roads, roads.sindex, roads.geometry.values, {})
    assert roads.loc[idx]['name'] == 'Zuideinde', (
        "Dual carriageway guard must block bonus: tertiary wins when opposing carriageway present"
    )


def test_intersection_bonus_bidirectional():
    """Bidirectional primary roads should always receive the bonus (regression check)."""
    import geopandas as gpd
    import pandas as pd
    from shapely.geometry import Point, LineString

    sign = pd.Series({
        'roadName': 'Kerkstraat',
        'bearing': 0.0,
        'side': 'L',
        'geometry': Point(0, 0)
    })

    # Bidirectional primary 30m east -> bonus fires -> primary wins.
    roads = gpd.GeoDataFrame([
        {
            'osm_id': 401, 'name': 'Daelderweg', 'highway': 'primary', 'priority': 1,
            'geometry': LineString([(30, 0), (30, 20)]),
            'other_tags': ''
        },
        {
            'osm_id': 402, 'name': 'Zuideinde', 'highway': 'tertiary', 'priority': 3,
            'geometry': LineString([(-8, 0), (-8, 20)]),
            'other_tags': ''
        }
    ], crs="EPSG:28992")
    idx, _ = snap_c9_to_roads.directional_snap(sign, roads, roads.sindex, roads.geometry.values, {})
    assert roads.loc[idx]['name'] == 'Daelderweg', (
        "Bidirectional primary must win via bonus (regression check)"
    )


def test_get_bearing_at_distance():
    from shapely.geometry import LineString
    from scripts import snap_c9_to_roads

    # Horizontal line from (0,0) to (100,0) -> bearing 0
    line = LineString([(0, 0), (100, 0)])
    assert snap_c9_to_roads.get_bearing_at_distance(line, 0.0) == pytest.approx(0.0)
    assert snap_c9_to_roads.get_bearing_at_distance(line, 50.0) == pytest.approx(0.0)
    assert snap_c9_to_roads.get_bearing_at_distance(line, 99.5) == pytest.approx(0.0)

    # Extremely short line
    short_line = LineString([(0, 0), (0.5, 0.5)])
    assert snap_c9_to_roads.get_bearing_at_distance(short_line, 0.2) == pytest.approx(45.0)


def test_has_opposing_carriageway_curved():
    import geopandas as gpd
    from shapely.geometry import LineString
    from scripts import snap_c9_to_roads

    # Curved Northbound: (0,0) -> (100,0) -> (100,200)
    # Midpoint is at (100,50). Local bearing near midpoint is North (90°).
    # Start bearing is East (0°).
    line_a = LineString([(0, 0), (100, 0), (100, 200)])

    # Curved Southbound: (115,200) -> (115,0) -> (215,0)
    # Midpoint is at (115,100). Local bearing near midpoint is South (270°).
    # Start bearing is South (270°).
    line_b = LineString([(115, 200), (115, 0), (215, 0)])

    roads_gdf = gpd.GeoDataFrame([
        {
            'osm_id': 601, 'name': 'ParallelRoad', 'highway': 'primary', 'priority': 1,
            'geometry': line_a, 'other_tags': '"oneway"=>"yes"'
        },
        {
            'osm_id': 602, 'name': 'ParallelRoad', 'highway': 'primary', 'priority': 1,
            'geometry': line_b, 'other_tags': '"oneway"=>"yes"'
        }
    ], crs="EPSG:28992")

    spatial_index = roads_gdf.sindex
    roads_geoms = roads_gdf.geometry.values

    # Test that line_a is detected as part of dual carriageway (opposing line_b nearby)
    is_dual = snap_c9_to_roads.has_opposing_carriageway(
        roads_gdf.iloc[0], line_a, roads_gdf, spatial_index, roads_geoms
    )
    assert is_dual, "Curved dual carriageway should be detected using local midpoint bearings"


def test_has_opposing_carriageway_flared():
    import geopandas as gpd
    from shapely.geometry import LineString
    from scripts import snap_c9_to_roads

    # Northbound going North-East (bearing 60°)
    line_a = LineString([(0, 0), (10, 17.32)])

    # Southbound going South-West, but flared at an angle of 200° (180 + 20)
    # The bearing difference is 200 - 60 = 140° (which is 40° off from 180° opposite).
    line_b = LineString([(5, 13.66), (1.58, 4.26)])

    roads_gdf = gpd.GeoDataFrame([
        {
            'osm_id': 701, 'name': 'FlaredRoad', 'highway': 'primary', 'priority': 1,
            'geometry': line_a, 'other_tags': '"oneway"=>"yes"'
        },
        {
            'osm_id': 702, 'name': 'FlaredRoad', 'highway': 'primary', 'priority': 1,
            'geometry': line_b, 'other_tags': '"oneway"=>"yes"'
        }
    ], crs="EPSG:28992")

    spatial_index = roads_gdf.sindex
    roads_geoms = roads_gdf.geometry.values

    # Flared road (diff = 140) should be detected under 45° tolerance (diff >= 135)
    is_dual = snap_c9_to_roads.has_opposing_carriageway(
        roads_gdf.iloc[0], line_a, roads_gdf, spatial_index, roads_geoms
    )
    assert is_dual, "Flared dual carriageway (bearing diff 140) should be detected with 45° tolerance"


def test_clean_snap_corrected_bearing():
    import geopandas as gpd
    import pandas as pd
    from shapely.geometry import Point, LineString
    # Sign facing West (bearing 270 geo) should match road going West (bearing 180 math, 270 geo)
    sign = pd.Series({
        'roadName': 'A1',
        'bearing': 270.0,
        'side': 'R',
        'geometry': Point(0, 0)
    })
    roads = gpd.GeoDataFrame([{
        'osm_id': 1, 'name': 'A1', 'highway': 'primary',
        'geometry': LineString([(0, 0), (-50, 0)]), 'other_tags': '' # Westbound
    }], crs="EPSG:28992")
    idx, _ = snap_c9_to_roads.directional_snap(sign, roads, roads.sindex, roads.geometry.values, {})
    assert idx == 0

def test_tie_breaking_priority():
    import geopandas as gpd
    import pandas as pd
    from shapely.geometry import Point, LineString
    # Sign for 'Kolkweg' (bearing 0 geo) near a primary and tertiary road, both unnamed
    sign = pd.Series({
        'roadName': 'Kolkweg',
        'bearing': 0.0,
        'side': 'R',
        'geometry': Point(0, 0)
    })
    roads = gpd.GeoDataFrame([
        # Primary (priority 1) 10m away
        {'osm_id': 1, 'name': None, 'highway': 'primary', 'geometry': LineString([(10, -50), (10, 50)]), 'other_tags': ''},
        # Tertiary (priority 3) 12m away
        {'osm_id': 2, 'name': None, 'highway': 'tertiary', 'geometry': LineString([(-12, -50), (-12, 50)]), 'other_tags': ''}
    ], crs="EPSG:28992")
    idx, _ = snap_c9_to_roads.directional_snap(sign, roads, roads.sindex, roads.geometry.values, {})
    # Primary should win due to higher priority class overriding the distance gap
    assert idx == 0

def test_tagging_direction_split():
    # Test split logic with converted geo bearing
    # Sign bearing is North (0 geo). Segment B goes North (90 math -> 0 geo).
    # Diff is 0 < 90 -> Restrict B.
    bearing_sign = 0.0
    bearing_B = 90.0 # math North
    diff = min(abs(bearing_sign - ((90 - bearing_B) % 360)), 360 - abs(bearing_sign - ((90 - bearing_B) % 360)))
    restrict_B = diff < 90.0
    assert restrict_B is True

def test_fallback_bearing_from_side():
    import pandas as pd
    # Sign bearing is NaN, side is 'O' (East -> 90 geo)
    sign = pd.Series({
        'roadName': 'Rijksweg',
        'bearing': float('nan'),
        'side': 'O',
        'geometry': Point(0, 0)
    })
    # Resolve bearing
    resolved_bearing = snap_c9_to_roads.get_bearing_from_side(sign['side'])
    assert resolved_bearing == 90.0

def test_intersection_bonus_name_match_aligned():
    import geopandas as gpd
    import pandas as pd
    from shapely.geometry import Point, LineString
    
    # Sign has roadName 'Erkemederweg', facing North (bearing 0.0)
    sign = pd.Series({
        'roadName': 'Erkemederweg',
        'bearing': 0.0,
        'side': 'N',
        'geometry': Point(0, 0)
    })
    
    # Two candidate roads:
    # 1. 'Nijkerkerweg' (primary, priority 1, aligned with bearing 0.0 -> goes North)
    # 2. 'Erkemederweg' (unclassified, priority 4, perpendicular to bearing 0.0 -> goes West/East)
    roads = gpd.GeoDataFrame([
        {
            'osm_id': 1, 'name': 'Nijkerkerweg', 'highway': 'primary',
            'geometry': LineString([(0.1, -10), (0.1, 10)]), 'other_tags': '' # Aligned
        },
        {
            'osm_id': 2, 'name': 'Erkemederweg', 'highway': 'unclassified',
            'geometry': LineString([(-10, 1), (10, 1)]), 'other_tags': '' # Perpendicular
        }
    ], crs="EPSG:28992")
    
    idx, _ = snap_c9_to_roads.directional_snap(sign, roads, roads.sindex, roads.geometry.values, {})
    # Since the name-matching candidate 'Erkemederweg' (osm_id 2) is perpendicular (angle_diff = 90° > 45°),
    # it should NOT count as an aligned name match. Therefore, 'any_name_matched' is False,
    # allowing 'Nijkerkerweg' (osm_id 1) to receive the intersection warning bonus and win!
    assert idx == 0

def test_snapping_interpolation_bearing():
    from shapely.geometry import LineString
    # A line from North (0, 100) to South (0, 0)
    line = LineString([(0, 100), (0, 0)])
    
    # The math bearing at 10m should be 270 degrees (pointing straight down)
    math_bearing = snap_c9_to_roads.get_bearing_at_distance(line, 10.0)
    assert math_bearing == pytest.approx(270.0)
    
    # Convert math bearing to geo bearing: (90 - math_bearing) % 360 = 180.0 (South)
    geo_bearing = (90 - math_bearing) % 360
    assert geo_bearing == pytest.approx(180.0)

def test_g_exemption_tagging():
    from unittest.mock import MagicMock
    from scripts import tag_c9_roads
    
    writer = MagicMock()
    handler = tag_c9_roads.TagC9Handler(writer, forbidden_ways={101}, way_snaps={}, exemption_ways={202})
    
    # Mock way 202 (NDW snapped exemption cycleway)
    mock_way = MagicMock()
    mock_way.id = 202
    mock_way.tags = {'highway': 'cycleway', 'access': 'no', 'motor_vehicle': 'no'}
    
    handler.way(mock_way)
    
    # Verify replaced tags set microcar=yes and motorized access=yes
    assert mock_way.replace.called
    called_tags = mock_way.replace.call_args[1]['tags']
    assert called_tags['microcar'] == 'yes'
    assert called_tags['motor_vehicle'] == 'yes'
    assert called_tags['vehicle'] == 'yes'
    assert called_tags['access'] == 'yes'
    assert called_tags['motorcar'] == 'yes'

def test_native_c9_tag_ingestion():
    import pandas as pd
    
    other_tags_series = pd.Series([
        '"agricultural"=>"no","traffic_sign"=>"NL:C9"',
        '"microcar"=>"no"',
        '"traffic_sign"=>"C9"',
        '"traffic_sign"=>"NL:C9","microcar"=>"yes"',
        '"traffic_sign"=>"NL:C9, OB65"',
        '"maxspeed"=>"50"'
    ])
    
    native_c9_mask = (
        other_tags_series.str.contains(r'traffic_sign.*C9', regex=True, case=False) |
        other_tags_series.str.contains(r'"microcar"=>"no"', regex=False)
    )
    has_exemption = (
        other_tags_series.str.contains(r'"microcar"=>"yes"', regex=False) |
        other_tags_series.str.contains(r'uitgezonderd|m\.u\.v\.|OB65|brommobiel.*toegestaan', regex=True, case=False)
    )
    native_c9_mask = native_c9_mask & (~has_exemption)
    
    matching_indices = list(other_tags_series[native_c9_mask].index)
    assert matching_indices == [0, 1, 2]

