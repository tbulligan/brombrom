import pytest
from unittest.mock import patch, MagicMock
import geopandas as gpd
from shapely.geometry import Point, LineString
import json
from scripts import debug_road

class MockCursor:
    def execute(self, sql, params=()):
        sql_lower = sql.lower()
        mock = MagicMock()
        
        if "from lines" in sql_lower:
            if "where osm_id =" in sql_lower:
                # Return single way matching osm_id
                mock.fetchone.return_value = ('Erkemederweg', 'unclassified', '"maxspeed"=>"80"', None)
                mock.fetchall.return_value = [('6971138', 'Erkemederweg', 'unclassified', '"maxspeed"=>"80"', None)]
            else:
                # search_by_name raw roads
                mock.fetchall.return_value = [('6971184', 'Erkemederweg', 'service', '"maxspeed"=>"60"', None)]
        elif "from brom_roads" in sql_lower:
            if "where osm_id =" in sql_lower:
                mock.fetchone.return_value = ('Erkemederweg', 'unclassified', 'no', json.dumps([{'lat': 52.2643, 'lon': 5.47257, 'bearing': 0.0}]))
            else:
                mock.fetchall.return_value = [('6971138', 'Erkemederweg', 'unclassified', 'no', json.dumps([{'lat': 52.2643, 'lon': 5.47257}]))]
        elif "from c9_ndw" in sql_lower:
            if "where id =" in sql_lower:
                mock.fetchone.return_value = ('ae8b784b-2ca7-417e-9619-38adcf55a761', 'Erkemederweg', 'C9', '[]', 'Zeewolde', 'Zeewolde', 0.0, 'https://wegkenmerken.ndw.nu/api/images/88a6829c', None)
            else:
                mock.fetchall.return_value = [('ae8b784b-2ca7-417e-9619-38adcf55a761', 'Erkemederweg', 'Zeewolde', '[]', None)]
        else:
            mock.fetchone.return_value = None
            mock.fetchall.return_value = []
        return mock

class MockConn:
    def cursor(self):
        return MockCursor()

def mock_sqlite_connect(database, *args, **kwargs):
    return MockConn()

def mock_read_file(filename, *args, **kwargs):
    if "nl_roads" in filename:
        return gpd.GeoDataFrame({
            'osm_id': ['6971138'],
            'name': ['Erkemederweg'],
            'highway': ['unclassified'],
            'other_tags': ['"maxspeed"=>"80"'],
            'geometry': [LineString([(5.47257, 52.2643), (5.473, 52.265)])]
        }, crs="EPSG:4326")
    return gpd.GeoDataFrame()

def mock_to_crs(*args, **kwargs):
    return gpd.GeoSeries([Point(0.5, 0.5)])

@patch("sqlite3.connect", side_effect=mock_sqlite_connect)
def test_inspect_way(mock_sqlite, capsys):
    debug_road.inspect_way(6971138)
    captured = capsys.readouterr()
    assert "INSPECTING WAY: 6971138" in captured.out
    assert "Processed/Blocked Road Data" in captured.out

@patch("sqlite3.connect", side_effect=mock_sqlite_connect)
def test_inspect_sign(mock_sqlite, capsys):
    debug_road.inspect_sign("ae8b784b-2ca7-417e-9619-38adcf55a761")
    captured = capsys.readouterr()
    assert "INSPECTING NDW SIGN: ae8b784b-2ca7-417e-9619-38adcf55a761" in captured.out
    assert "Erkemederweg" in captured.out

@patch("sqlite3.connect", side_effect=mock_sqlite_connect)
def test_search_by_name(mock_sqlite, capsys):
    debug_road.search_by_name("Erkemederweg")
    captured = capsys.readouterr()
    assert "SEARCHING FOR ROAD NAME: 'Erkemederweg'" in captured.out
    assert "Matching NDW C9 Signs" in captured.out

@patch("sqlite3.connect", side_effect=mock_sqlite_connect)
@patch("geopandas.read_file", side_effect=mock_read_file)
@patch("geopandas.GeoSeries.to_crs", side_effect=mock_to_crs)
def test_inspect_coords(mock_to_crs, mock_read, mock_sqlite, capsys):
    debug_road.inspect_coords(52.2643, 5.47257)
    captured = capsys.readouterr()
    assert "INSPECTING COORDINATES: (52.2643, 5.47257)" in captured.out
    assert "Closest road segment found" in captured.out
    assert "INSPECTING WAY: 6971138" in captured.out
