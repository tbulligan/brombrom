import pytest
import sqlite3
import struct
import json
from unittest.mock import patch
import geopandas as gpd
from shapely.geometry import Point, LineString
from scripts import debug_road

def create_in_memory_db():
    """Create a real, fully-functional in-memory SQLite database populated with test schema and rows."""
    conn = sqlite3.connect(":memory:")
    cur = conn.cursor()
    
    # 1. Create tables with exact production GeoPackage schemas
    cur.execute("""
        CREATE TABLE lines (
            fid INTEGER PRIMARY KEY,
            osm_id TEXT,
            name TEXT,
            highway TEXT,
            other_tags TEXT,
            geom BLOB
        );
    """)
    
    cur.execute("""
        CREATE TABLE brom_roads (
            fid INTEGER PRIMARY KEY,
            osm_id TEXT,
            name TEXT,
            highway TEXT,
            other_tags TEXT,
            microcar TEXT,
            c9_snaps TEXT,
            geom BLOB
        );
    """)
    
    cur.execute("""
        CREATE TABLE c9_ndw (
            fid INTEGER PRIMARY KEY,
            id TEXT,
            roadName TEXT,
            rvvCode TEXT,
            textSigns TEXT,
            countyName TEXT,
            townName TEXT,
            bearing REAL,
            imageUrl TEXT,
            geom BLOB
        );
    """)
    
    # 2. Build test GPB WGS84 point BLOB for (5.47257, 52.2643)
    gpb_point_blob = b'GP\x00\x00\x00\x00\x00\x00\x01\x01\x00\x00\x00' + struct.pack('<dd', 5.47257, 52.2643)
    
    snaps_json = json.dumps([{
        'id': 'ae8b784b-2ca7-417e-9619-38adcf55a761',
        'lat': 52.2643,
        'lon': 5.47257,
        'bearing': 0.0
    }])
    
    # 3. Populate sample test rows
    cur.execute(
        "INSERT INTO lines (osm_id, name, highway, other_tags, geom) VALUES (?, ?, ?, ?, ?)",
        ('6971138', 'Erkemederweg', 'unclassified', '"maxspeed"=>"80"', gpb_point_blob)
    )
    cur.execute(
        "INSERT INTO lines (osm_id, name, highway, other_tags, geom) VALUES (?, ?, ?, ?, ?)",
        ('6971184', 'Erkemederweg', 'service', '"maxspeed"=>"60"', gpb_point_blob)
    )
    
    cur.execute(
        "INSERT INTO brom_roads (osm_id, name, highway, microcar, c9_snaps, geom) VALUES (?, ?, ?, ?, ?, ?)",
        ('6971138', 'Erkemederweg', 'unclassified', 'no', snaps_json, gpb_point_blob)
    )
    
    cur.execute(
        "INSERT INTO c9_ndw (id, roadName, rvvCode, textSigns, countyName, townName, bearing, imageUrl, geom) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        ('ae8b784b-2ca7-417e-9619-38adcf55a761', 'Erkemederweg', 'C9', '[]', 'Zeewolde', 'Zeewolde', 0.0, 'https://wegkenmerken.ndw.nu/api/images/88a6829c', gpb_point_blob)
    )
    
    conn.commit()
    return conn

@pytest.fixture
def memory_db():
    conn = create_in_memory_db()
    yield conn
    conn.close()

def mock_connect_factory(conn):
    """Return factory function that returns shared in-memory connection."""
    def _mock_connect(*args, **kwargs):
        return conn
    return _mock_connect

def mock_read_file(filename, *args, **kwargs):
    if "nl_roads" in filename:
        return gpd.GeoDataFrame({
            'osm_id': ['6971138'],
            'name': ['Erkemederweg'],
            'highway': ['unclassified'],
            'other_tags': ['"maxspeed"=>"80"'],
            'geometry': [LineString([(155000, 463000), (155100, 463100)])]
        }, crs="EPSG:28992")
    return gpd.GeoDataFrame()

def mock_to_crs(*args, **kwargs):
    return gpd.GeoSeries([Point(0.5, 0.5)], crs="EPSG:28992")

def test_inspect_way(memory_db, capsys):
    with patch("sqlite3.connect", side_effect=mock_connect_factory(memory_db)):
        debug_road.inspect_way(6971138)
        captured = capsys.readouterr()
        assert "INSPECTING WAY: 6971138" in captured.out
        assert "Processed/Blocked Road Data" in captured.out
        assert "🔴 BLOCKED (microcar: no)" in captured.out
        assert "https://www.openstreetmap.org/way/6971138" in captured.out

def test_inspect_sign(memory_db, capsys):
    with patch("sqlite3.connect", side_effect=mock_connect_factory(memory_db)):
        debug_road.inspect_sign("ae8b784b-2ca7-417e-9619-38adcf55a761")
        captured = capsys.readouterr()
        assert "INSPECTING NDW SIGN: ae8b784b-2ca7-417e-9619-38adcf55a761" in captured.out
        assert "Erkemederweg" in captured.out
        assert "52.26430, 5.47257" in captured.out
        assert "Sign successfully snapped to 1 road segment(s):" in captured.out

def test_search_by_name(memory_db, capsys):
    with patch("sqlite3.connect", side_effect=mock_connect_factory(memory_db)):
        debug_road.search_by_name("Erkemederweg", level0_format=True)
        captured = capsys.readouterr()
        assert "SEARCHING FOR ROAD NAME: 'Erkemederweg'" in captured.out
        assert "Matching NDW C9 Signs" in captured.out
        assert "Matching Blocked Roads" in captured.out
        assert "Matching Raw/Allowed Roads" in captured.out
        assert "w6971184" in captured.out

def test_inspect_coords(memory_db, capsys):
    with patch("sqlite3.connect", side_effect=mock_connect_factory(memory_db)):
        with patch("geopandas.read_file", side_effect=mock_read_file):
            with patch("geopandas.GeoSeries.to_crs", side_effect=mock_to_crs):
                debug_road.inspect_coords(52.2643, 5.47257)
                captured = capsys.readouterr()
                assert "INSPECTING COORDINATES: (52.2643, 5.47257)" in captured.out
                assert "Closest road segment found" in captured.out
                assert "INSPECTING WAY: 6971138" in captured.out
