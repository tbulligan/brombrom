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
        'bearing': 90.0,
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


def test_intersection_bonus_blocked_for_oneway():
    """The Intersection Warning Bonus must NOT fire for one-way roads.

    Dual carriageways (e.g. N298 Daelderweg) are two parallel one-way roads.
    Without this guard, a C9 sign from a side street can snap to one
    carriageway but not the other, blocking microcars in only one direction.

    Geometry note: directional_snap uses line.interpolate(ahead_frac) with
    normalized=False (absolute metres), so seg_bearing depends on the
    digitisation direction relative to proj_dist. To get a predictable
    seg_bearing, roads are short (20m) and the sign projects near their start
    so seg_end is clearly ahead in the digitisation direction.

    Sign bearing=90 (north). Roads run north (from y=0 toward y=20).
    For one-way roads angle_diff uses the road's actual bearing; for
    bidirectional roads the minimum of forward/reverse is taken.
    """
    import geopandas as gpd
    import pandas as pd
    from shapely.geometry import Point, LineString

    # Sign on a side street, facing north (bearing=90), at origin.
    sign = pd.Series({
        'roadName': 'Kerkstraat',
        'bearing': 90.0,
        'side': 'L',   # sign is to the left of a northbound road = west side
        'geometry': Point(0, 0)
    })

    # Scenario B: one-way primary 30m east (digitised northward = bearing 90°),
    # bidirectional tertiary 8m west (also digitised northward).
    # sign bearing=90, road bearing=90 -> angle_diff=0 for both.
    # Bonus BLOCKED for primary (oneway). Scores:
    #   primary:  30*0.7 + 0*0.15 + 0 + 0 + 30 = 51.0
    #   tertiary:  8*0.7 + 0*0.15 + 0 + 2 + 30 = 37.6  <- wins
    roads_b = gpd.GeoDataFrame([
        {
            'osm_id': 301, 'name': 'Daelderweg', 'highway': 'primary', 'priority': 1,
            'geometry': LineString([(30, 0), (30, 20)]),   # northbound, 30m east
            'other_tags': '"oneway"=>"yes"'
        },
        {
            'osm_id': 302, 'name': 'Zuideinde', 'highway': 'tertiary', 'priority': 3,
            'geometry': LineString([(-8, 0), (-8, 20)]),   # northbound, 8m west
            'other_tags': ''
        }
    ], crs="EPSG:28992")
    idx_b, _ = snap_c9_to_roads.directional_snap(sign, roads_b, roads_b.sindex, roads_b.geometry.values, {})
    assert roads_b.loc[idx_b]['name'] == 'Zuideinde', (
        "One-way guard must prevent bonus: tertiary wins when one-way primary is farther"
    )

    # Scenario C: same layout but primary is bidirectional — bonus FIRES.
    # Scores:
    #   primary:  30*0.7 + 0 + 0 +  0 = 21.0  <- wins (bonus removes name penalty)
    #   tertiary:  8*0.7 + 0 + 2 + 30 = 37.6
    roads_c = gpd.GeoDataFrame([
        {
            'osm_id': 401, 'name': 'Daelderweg', 'highway': 'primary', 'priority': 1,
            'geometry': LineString([(30, 0), (30, 20)]),   # same position, bidirectional
            'other_tags': ''
        },
        {
            'osm_id': 402, 'name': 'Zuideinde', 'highway': 'tertiary', 'priority': 3,
            'geometry': LineString([(-8, 0), (-8, 20)]),
            'other_tags': ''
        }
    ], crs="EPSG:28992")
    idx_c, _ = snap_c9_to_roads.directional_snap(sign, roads_c, roads_c.sindex, roads_c.geometry.values, {})
    assert roads_c.loc[idx_c]['name'] == 'Daelderweg', (
        "Bidirectional primary must win via bonus (regression check for original behaviour)"
    )
