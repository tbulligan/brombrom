# Testing & Quality Assurance

This project includes a suite of unit tests and validation scripts to ensure the accuracy of the microcar restriction logic.

## Unit Tests

Unit tests are located in the `tests/` directory and focus on the core algorithms used in the ETL pipeline.

### Coverage
- **Exemption Logic**: Validates that traffic signs are correctly identified as having microcar exemptions (e.g., `OB65`, `uitgezonderd brommobielen`), including handling of common OCR typos.
- **Bearing Calculation**: Ensures that directional snapping correctly calculates angles between points.
- **Geometric Side Detection**: Validates the cross-product logic used to determine if a sign is on the left or right of a road segment.

### Running Tests
To run the unit tests, use the standard Python `unittest` module from the project root:

```bash
# Using the project's recommended environment
pytest
```

## Validation & Results QC

In addition to unit tests, the `run_full_build.sh` pipeline includes a QA validation step:

1. **`validate_results.py`**: Automatically runs at the end of every build to check the integrity of the generated `.obf` and `.pbf` files.
2. **Debug Mode**: Running with `DEBUG=true` generates `debug_snaps.gpkg`. You can open this file in **QGIS** to visually inspect the snapping results. Blue lines connect each source C9 sign to its snapped road position.

## Continuous Integration
Tests are automatically executed on every push to the `develop` and `main` branches via GitHub Actions using `pytest`.
