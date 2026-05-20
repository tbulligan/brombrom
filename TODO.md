# BromBrom Future Improvements

This document tracks technical debt and potential enhancements for the BromBrom navigation engine.

## 🛠️ High Priority
- [ ] **Robust Way Splitting**: Implement logic in `tag_c9_roads.py` to split long OSM ways at the exact point of a C9 restriction. This prevents "whole-road" blocking where only a segment is restricted.
- [ ] **QA Validation Expansion**: Enhance `scripts/validate_results.py` to compare current statistics against "known good" historic baselines to catch subtle data regressions.

## 🔍 Research & Exploration
- [ ] **Custom Rendering Styles**: Investigate using a custom `rendering_types.xml` to highlight C9-restricted roads in the OsmAnd UI (e.g., bright red overlay).
    - *UX Concern*: Must evaluate if this is informative or too distracting for standard navigation.

## 📦 Distribution & Release
- [ ] **Google Play Store Release**: Complete developer registration and onboarding steps to publish the BromBrom Manager app on the Play Store (WIP).
