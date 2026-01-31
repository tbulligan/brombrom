import unittest
from shapely.geometry import Point, LineString
from scripts import snap_c9_to_roads
import math

class TestSnappingLogic(unittest.TestCase):
    def test_exemption_logic(self):
        # Test normal exemption
        self.assertTrue(snap_c9_to_roads.has_microcar_exemption({'textSigns': 'uitgezonderd brommobielen'}))
        self.assertTrue(snap_c9_to_roads.has_microcar_exemption({'textSigns': 'm.u.v. brommobiel'}))

        # Test OCR typo (intentional support)
        self.assertTrue(snap_c9_to_roads.has_microcar_exemption({'textSigns': 'uitgezonderd brommoblelen'}))

        # Test OB65 code
        self.assertTrue(snap_c9_to_roads.has_microcar_exemption({'textSigns': 'OB65'}))

        # Test negative cases
        self.assertFalse(snap_c9_to_roads.has_microcar_exemption({'textSigns': 'uitgezonderd fietsers'}))
        self.assertFalse(snap_c9_to_roads.has_microcar_exemption({'textSigns': 'vrachtverkeer'}))
        self.assertFalse(snap_c9_to_roads.has_microcar_exemption({'textSigns': ''}))
        self.assertFalse(snap_c9_to_roads.has_microcar_exemption({}))

    def test_bearing_calculation(self):
        # Current implementation uses Math Angle (0=East, 90=North)
        p1 = Point(0, 0)

        # East
        p2 = Point(1, 0)
        self.assertAlmostEqual(snap_c9_to_roads.bearing_between(p1, p2), 0.0)

        # North
        p3 = Point(0, 1)
        self.assertAlmostEqual(snap_c9_to_roads.bearing_between(p1, p3), 90.0)

        # West
        p4 = Point(-1, 0)
        self.assertAlmostEqual(snap_c9_to_roads.bearing_between(p1, p4), 180.0)

        # South
        p5 = Point(0, -1)
        self.assertAlmostEqual(snap_c9_to_roads.bearing_between(p1, p5), 270.0)

    def test_geometric_side(self):
        # Vertical line going North (0,0) -> (0,10)
        line = LineString([(0, 0), (0, 10)])

        # Point to the Left (-x)
        # Cross product of (0,10) and (-2, 5)
        # dx=0, dy=10
        # vx=-2, vy=5
        # cp = 0*5 - 10*(-2) = 20 > 0 -> 'L'
        p_left = Point(-2, 5)
        self.assertEqual(snap_c9_to_roads.get_geometric_side(p_left, line, 5.0), 'L')

        # Point to the Right (+x)
        # vx=2, vy=5
        # cp = 0*5 - 10*2 = -20 < 0 -> 'R'
        p_right = Point(2, 5)
        self.assertEqual(snap_c9_to_roads.get_geometric_side(p_right, line, 5.0), 'R')

        # Point on line (approx)
        p_on = Point(0, 5)
        self.assertIsNone(snap_c9_to_roads.get_geometric_side(p_on, line, 5.0))

if __name__ == '__main__':
    unittest.main()
