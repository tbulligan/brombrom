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


def test_validate_osf_archive_checks_cemt_marker_when_gated(tmp_path, monkeypatch):
    monkeypatch.setattr(validate_results, "MIN_EXPECTED_OBF_SIZE_MB", 0)
    gated_xml = (
        "<osmand_routing_config><routingProfile name='BromBrom'>"
        "<way attribute='access'><ifnot t='cemt' v='brombrom'><select value='-1'/></ifnot></way>"
        "</routingProfile></osmand_routing_config>"
    )

    stale_osf = tmp_path / "stale.osf"
    _write_osf(
        stale_osf,
        {
            "items.json": "{}",
            "profile_brombrom.json": "{}",
            "routing/routing.xml": gated_xml,
            "NL_BromBrom_tagged.obf": b"\x08\x02Nl_brombrom_tagged\x12\x08\x1a\x04name*\x00",
        },
    )
    with pytest.raises(ValueError, match="cemt=brombrom"):
        validate_results.validate_osf_archive(str(stale_osf))

    fresh_osf = tmp_path / "fresh.osf"
    _write_osf(
        fresh_osf,
        {
            "items.json": "{}",
            "profile_brombrom.json": "{}",
            "routing/routing.xml": gated_xml,
            "NL_BromBrom_tagged.obf": b"\x08\x02Nl_brombrom_tagged" + validate_results.OBF_BROMBROM_RULE_BYTES,
        },
    )
    validate_results.validate_osf_archive(str(fresh_osf))
