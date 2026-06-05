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

