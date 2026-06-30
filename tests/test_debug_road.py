import pytest
from scripts import debug_road

def test_inspect_way(capsys):
    # Node/Way 6971138 is the Erkemederweg which should be in the DB
    debug_road.inspect_way(6971138)
    captured = capsys.readouterr()
    assert "INSPECTING WAY: 6971138" in captured.out
    assert "Processed/Blocked Road Data" in captured.out

def test_inspect_sign(capsys):
    # Sign ae8b784b-2ca7-417e-9619-38adcf55a761 is on Erkemederweg
    debug_road.inspect_sign("ae8b784b-2ca7-417e-9619-38adcf55a761")
    captured = capsys.readouterr()
    assert "INSPECTING NDW SIGN: ae8b784b-2ca7-417e-9619-38adcf55a761" in captured.out
    assert "Erkemederweg" in captured.out

def test_search_by_name(capsys):
    debug_road.search_by_name("Erkemederweg")
    captured = capsys.readouterr()
    assert "SEARCHING FOR ROAD NAME: 'Erkemederweg'" in captured.out
    assert "Matching NDW C9 Signs" in captured.out
