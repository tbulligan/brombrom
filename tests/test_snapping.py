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

    # Test negative cases
    assert not snap_c9_to_roads.has_microcar_exemption({'textSigns': 'uitgezonderd fietsers'})
    assert not snap_c9_to_roads.has_microcar_exemption({'textSigns': 'vrachtverkeer'})
    assert not snap_c9_to_roads.has_microcar_exemption({'textSigns': ''})
    assert not snap_c9_to_roads.has_microcar_exemption({})

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
