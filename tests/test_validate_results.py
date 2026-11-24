import json
import zipfile

import pytest

from scripts import validate_results


def _write_osf(path, entries):
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as zf:
        for name, data in entries.items():
            zf.writestr(name, data)


def test_validate_osf_archive_passes(tmp_path, monkeypatch):
    monkeypatch.setattr(validate_results, "MIN_EXPECTED_OBF_SIZE_MB", 0)
    osf = tmp_path / "BromBrom.osf"
    _write_osf(
        osf,
        {
            "items.json": json.dumps({"version": 3, "items": []}),
            "profile_brombrom.json": json.dumps({"default_speed": "12.5"}),
            "routing/routing.xml": "<osmand_routing_config/>",
            "NL_BromBrom_tagged.obf": b"fake-obf-bytes",
        },
    )
    validate_results.validate_osf_archive(str(osf))


def test_validate_osf_archive_rejects_missing_member(tmp_path):
    osf = tmp_path / "BromBrom.osf"
    _write_osf(
        osf,
        {
            "items.json": "{}",
            "profile_brombrom.json": "{}",
            "routing/routing.xml": "<osmand_routing_config/>",
        },
    )
    with pytest.raises(ValueError, match="NL_BromBrom_tagged.obf"):
        validate_results.validate_osf_archive(str(osf))


def test_validate_osf_archive_rejects_invalid_xml(tmp_path, monkeypatch):
    monkeypatch.setattr(validate_results, "MIN_EXPECTED_OBF_SIZE_MB", 0)
    osf = tmp_path / "BromBrom.osf"
    _write_osf(
        osf,
        {
            "items.json": "{}",
            "profile_brombrom.json": "{}",
            "routing/routing.xml": "<broken",
            "NL_BromBrom_tagged.obf": b"data",
        },
    )
    with pytest.raises(Exception):
        validate_results.validate_osf_archive(str(osf))
