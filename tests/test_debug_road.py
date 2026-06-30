import pytest
from unittest.mock import patch
import geopandas as gpd
from shapely.geometry import Point, LineString
import json
from scripts import debug_road

def mock_read_file(filename, *args, **kwargs):
    if "nl_roads_brom" in filename:
        return gpd.GeoDataFrame({
            'osm_id': ['6971138'],
            'name': ['Erkemederweg'],
            'highway': ['unclassified'],
            'exempt': [None],
            'c9_snaps': [json.dumps([{'lat': 52.2643, 'lon': 5.47257, 'bearing': 0.0}])],
            'geometry': [LineString([(0, 0), (1, 1)])]
        })
    elif "nl_roads" in filename:
        return gpd.GeoDataFrame({
            'osm_id': ['6971138', '6971184'],
            'name': ['Erkemederweg', 'Erkemederweg'],
            'highway': ['unclassified', 'service'],
            'other_tags': ['"maxspeed"=>"80"', '"maxspeed"=>"60"'],
            'geometry': [LineString([(0, 0), (1, 1)]), LineString([(1, 1), (2, 2)])]
        })
    elif "c9_ndw" in filename:
        return gpd.GeoDataFrame({
            'id': ['ae8b784b-2ca7-417e-9619-38adcf55a761'],
            'roadName': ['Erkemederweg'],
            'rvvCode': ['C9'],
            'textSigns': ['[]'],
            'countyName': ['Zeewolde'],
            'townName': ['Zeewolde'],
            'bearing': [0.0],
            'imageUrl': ['https://wegkenmerken.ndw.nu/api/images/88a6829c-2e0f-47be-ba8b-f2d3b60a2a15'],
            'geometry': [Point(5.47257, 52.2643)]
        })
    return gpd.GeoDataFrame()

def mock_to_crs(*args, **kwargs):
    return gpd.GeoSeries([Point(0.5, 0.5)])

@patch("geopandas.read_file", side_effect=mock_read_file)
def test_inspect_way(mock_read, capsys):
    # Node/Way 6971138 is the Erkemederweg which should be in the DB
    debug_road.inspect_way(6971138)
    captured = capsys.readouterr()
    assert "INSPECTING WAY: 6971138" in captured.out
    assert "Processed/Blocked Road Data" in captured.out

@patch("geopandas.read_file", side_effect=mock_read_file)
def test_inspect_sign(mock_read, capsys):
    # Sign ae8b784b-2ca7-417e-9619-38adcf55a761 is on Erkemederweg
    debug_road.inspect_sign("ae8b784b-2ca7-417e-9619-38adcf55a761")
    captured = capsys.readouterr()
    assert "INSPECTING NDW SIGN: ae8b784b-2ca7-417e-9619-38adcf55a761" in captured.out
    assert "Erkemederweg" in captured.out

@patch("geopandas.read_file", side_effect=mock_read_file)
def test_search_by_name(mock_read, capsys):
    debug_road.search_by_name("Erkemederweg")
    captured = capsys.readouterr()
    assert "SEARCHING FOR ROAD NAME: 'Erkemederweg'" in captured.out
    assert "Matching NDW C9 Signs" in captured.out

@patch("geopandas.read_file", side_effect=mock_read_file)
@patch("geopandas.GeoSeries.to_crs", side_effect=mock_to_crs)
def test_inspect_coords(mock_to_crs, mock_read, capsys):
    debug_road.inspect_coords(52.2643, 5.47257)
    captured = capsys.readouterr()
    assert "INSPECTING COORDINATES: (52.2643, 5.47257)" in captured.out
    assert "Closest road segment found" in captured.out
    assert "INSPECTING WAY: 6971138" in captured.out
