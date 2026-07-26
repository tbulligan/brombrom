# Snapping & Spatial Logic

## Overview
The heart of BromBrom is its directional snapping, name-matching validation, and pre-warning/exemption parsing logic. This ensures that C9 traffic signs from the NDW dataset are correctly mapped to OpenStreetMap road segments.

## Snapping Candidates & Search Tolerances
To map C9 sign points to OSM linestrings, BromBrom queries road candidates around each sign. The query logic depends on the sign's metadata:
- **If the sign lacks both bearing and relative side info**: A two-tier spatial search is performed.
  1. **Primary Search**: Query a narrow bounding box around the sign point (`PRIMARY_TOL = 2.0` meters).
  2. **Fallback Search**: If no candidates are found, query a wider bounding box (`FALLBACK_TOL = 60.0` meters).
- **If the sign has bearing or relative side info**: The search queries the wider fallback bounding box (`FALLBACK_TOL = 60.0` meters) directly.

Using a fallback tolerance of 60 meters accommodates NDW GPS inaccuracies while name-matching and bearing constraints prevent incorrect snaps to adjacent roads.

### Sign & Candidate Filtering
To ensure only active restrictions are mapped and to prevent false-positive closures:
- **Inactive Signs**: C9 signs that are marked as removed or whose status is not `PLACED` are filtered out before snapping.
- **Pre-warning Metadata Filtering**: Signs containing `type: "VOOR"` in their `textSigns` attribute are filtered out before snapping.
- **Roundabouts**: Roundabouts (`junction=roundabout` or roundabout highway classes) are excluded from the snapping candidate pool entirely to avoid blocking general intersection routing for microcars.
- **Minor Roads Penalty**: Road segments with highway classes mapping to priority >= 4 (such as `residential`, `unclassified`, `service`, `living_street`, `track`, and `road`) are not excluded from snapping candidates, but receive a priority penalty of `+8.0` in scoring (see below) to prefer snapping to high-priority roads at junctions.
- **Post-Snap Priority Filter**: Roads with highway classes mapping to priority >= 10 (e.g. non-road types) are filtered out post-snap by resetting their snap to `None`.

## Snapping Score Formulation
When multiple candidate road segments are found, they are scored using a weighted formulation. The road with the lowest score is selected:

$$\text{Score} = (\text{Distance} \times 0.7) + (\text{Angle Difference} \times 0.15) + \text{Side Penalty} + \text{Priority Penalty} + \text{Name Penalty}$$

This ensures distance is the primary metric, while orientation, side alignment, highway class, and road names refine the snap.

### 1. Orientation & Bearing Matching
- The sign's cardinal placement (`side` mapped to wind-rose angles) or explicit `bearing` is compared to the segment's bearing in standard geographical coordinates (where $0^\circ = \text{North}$, $90^\circ = \text{East}$).
- Mathematical road bearings ($M$) calculated from segment geometries are converted to geographical coordinates ($G$) via $G = (90 - M) \pmod{360}$ before matching.
- For bi-directional roads, the sign's bearing can match either the forward or backward road bearing to handle digitization directions safely.

### 2. Geometric Side Matching (2D Cross-Product)
For relative siding (`L`/`R`), the sign position is projected onto the road segment:
- A 2D cross-product determines if the sign is geometrically on the left or right of the road.
- **Score Bonus**: If the physical placement matches the geometric side, a bonus of `-2.0` (equivalent to being ~2.8m closer) is applied. Mismatches do not receive a penalty to prevent false-negative exclusions (e.g. at highway junctions).

### 3. Highway Priority Penalty
To prevent signs from snapping to minor parallel roads (like residential streets or cycleways mapped as roads), a penalty is applied based on the highway class:
- `residential`, `living_street`, `service`, `unclassified` (Priority >= 4): `+8.0` penalty.
- `tertiary`, `tertiary_link` (Priority = 3): `+2.0` penalty.
- `primary`, `secondary`, `trunk`, `motorway` (Priority <= 2): `+0.0` penalty.

### 4. Name Matching Validation
To prevent snaps onto crossing roads or parallel routes of a different road:
- The normalized NDW road name is matched against the normalized OSM road name (stripping suffixes like *straatweg*, *weg*, *dijk*, etc.). Exact stem matches always succeed; substring containment matches (e.g. `"amsterdam"` in `"nieuwamsterdam"`) require both stems to be at least 4 characters long to prevent false collisions between short stems like `"kerk"` matching both *Kerkweg* and *Kerkstraat*.
- **Name Penalty**: If the names do not match, a penalty of `+30.0` is applied (equivalent to being ~43m further away). This ensures that name-matching segments are strongly preferred.
- **Alignment Check for Name Matching**: To prevent perpendicular crossing roads from matching on name and blocking adjacent routing, a candidate is only counted as a name match for the sign if it is also roughly aligned with the sign's bearing (`angle_diff <= 45.0` or no sign bearing available).
- **Intersection Warning Bonus (Conditional)**: If no candidate road matches the NDW sign's road name (e.g., because matching minor roads were excluded), the name penalty is reduced to `0.0` for any high-priority **non-link** road (`priority <= 2` and not ending in `_link`) within 50 meters whose bearing matches the sign's bearing within 30 degrees. This allows intersection pre-warnings on side streets to correctly snap to the main restricted highway instead of other local crossing roads or ramps.
- **Dual-carriageway guard**: This bonus is NOT applied to roads detected as part of a dual carriageway. A dual carriageway is identified when a parallel one-way road of similar highway class runs in the opposite direction within 20 metres. This prevents asymmetric blocking where a C9 sign would snap to one carriageway but not the other (e.g. N298 Daelderweg). Single (non-divided) one-way roads still receive the bonus. Link roads (highways ending with `_link`, like entry/exit ramps) are excluded from the dual-carriageway check to allow pre-warnings at junctions.

## Pre-Warning Filtering & Validation
Pre-warning signs (voorwaarschuwingsborden) warn drivers about a downstream restriction. They do not represent active restrictions and must be ignored to prevent false closures.

### 1. Metadata-based Filtering
Signs containing `type: "VOOR"` in their `textSigns` attribute (indicating a warning in e.g. 500m) are filtered out immediately.

### 2. Post-Snapping Downstream Heuristic
Since many pre-warnings lack complete metadata in NDW (empty `textSigns`), BromBrom employs a downstream validation heuristic:
- If a sign A snaps to a low-speed road segment (`maxspeed <= 50` or minor road classes) but another C9 sign B exists downstream on the same road (matching normalized names) within **300.0 m** and heading in a similar direction (bearing difference <= 45°), and B snaps to a high-speed road (`maxspeed > 50` or `trunk`/`motorway` class):
- Sign A is flagged as a pre-warning and ignored, while the downstream sign B remains to enforce the restriction where it actually starts.

## Exemption Parsing & G-Exemption Snapping
Beyond spatial snapping for C9 prohibitions, BromBrom accurately parses "onderborden" (sub-plates) to identify signs that explicitly allow microcar access (`OB65`, *"uitgezonderd brommobielen"*, *"brommobielen toegestaan"*):
- **Official Codes**: Recognizes standard Dutch exemption codes like `OB65`.
- **Fuzzy Text Matching**: Handles complex Dutch text (e.g., `uitgezonderd brommobielen`, `brommobielen toegestaan`) and is resilient to OCR-prone typos (e.g., `brommoblelen`).
- **Negative Guards**: Prevents false exemptions by identifying explicit prohibitions like *"Geldt ook voor brommobiel"* (Also applies to microcars).
- **G-Exemption Snapping Pipeline**: NDW traffic sign data is extracted for G12a (*fiets/bromfietspad*), G11 (*verplicht fietspad*), C12, and C9 signs with positive microcar exemptions (`extract_c9.py`). These signs are directionally snapped to candidate OSM ways (`highway=cycleway`, `path`, `track`, `service`, `unclassified`) in [snap_c9_to_roads.py](file:///home/tomaso/projects/brombrom/scripts/snap_c9_to_roads.py) and output to `g_exemptions_ways.json`.

### Native OSM C9 Tag Ingestion
In addition to spatial snapping of NDW C9 point signs, [snap_c9_to_roads.py](file:///home/tomaso/projects/brombrom/scripts/snap_c9_to_roads.py) automatically ingests all road segments in OpenStreetMap natively tagged with `traffic_sign=NL:C9` (or `C9` variants / `microcar=no`). These segments are directly added to the restricted road dataset (`nl_roads_brom.gpkg`) unless they carry an explicit `microcar=yes` override tag. This ensures full coverage across multi-segment highways where NDW point signs might not snap to every individual segment.

## Custom OSM Tagging & Routing Overrides
During the PBF tagging pipeline ([tag_c9_roads.py](file:///home/tomaso/projects/brombrom/scripts/tag_c9_roads.py)) and routing profile configuration ([routing.xml](file:///home/tomaso/projects/brombrom/config/routing.xml)), custom translation rules and geometry modifications are applied to the OSM data to ensure [OsmAnd](https://www.osmand.net/)'s routing engine respects microcar accessibility correctly:

### 1. Roundabout Physical Exit Indexing & Access Cost Calibration
- In [routing.xml](file:///home/tomaso/projects/brombrom/config/routing.xml), main forbidden highways (`motorway`, `trunk`, `motorroad=yes`, `microcar=no`) use `select value="-1"` (hard drop from graph) to prevent A* routing freezes. Link ramps (`motorway_link`, `trunk_link`) use `select value="0"` in `<way attribute="access">` paired with `select value="36000"` (10h transition penalty) in `<way attribute="penalty_transition">`.
- **Maneuver Engine Exit Counting**: Hard-dropping main motorways prunes 99.9% of restricted highway geometry to maintain millisecond routing speeds nationwide. Retaining link ramps in the access graph (`value="0"`) ensures OsmAnd's maneuver engine accurately counts physical roundabout exit ramps (*"Neem de 2e afslag naar Keizersveer"*), while `penalty_transition="36000"` prevents Dijkstra / A* route planning from navigating microcars onto ramps.

### 2. Existing OSM Tag Conversions & NDW Exemption Allowances
- **Microcar Prohibitions (`microcar=no`)**: Promoted to `motor_vehicle=no` (if `motor_vehicle` is not already restricted) to enforce C9 restrictions inside [OsmAnd](https://www.osmand.net/).
- **Microcar Allowances (`microcar=yes`) & NDW G-Exemption Ways**: Bypasses general motorized restrictions. If a road is tagged with `microcar=yes` or identified in `g_exemptions_ways.json`, the pipeline sets `microcar=yes` **AND** overrides general motorized access tags (`motor_vehicle=yes`, `vehicle=yes`, `access=yes`, `motorcar=yes`) to restore microcar routing access inside [OsmAnd](https://www.osmand.net/).

### 3. NDW Pipeline Way Splitting & Directional Tagging
When a road segment is identified as C9-forbidden by the snapping pipeline, it is processed as follows:
- **Way Splitting**: If the C9 sign snaps in the middle of an OSM way (specifically, at least 5.0 meters away from both the start and end nodes of a way containing at least 3 nodes), the way is split into two separate segments: segment A (from start to split node) and segment B (from split node to end).
- **Directional Restriction**: The pipeline compares the geographical bearing of the C9 sign to the local bearing of segment B (from split node to next node):
  - If the sign bearing is within 90 degrees of segment B's bearing, the sign restricts segment B. Segment B is tagged with `motor_vehicle=no` and `microcar=no`.
  - Otherwise, the sign restricts segment A. Segment A is tagged with `motor_vehicle=no` and `microcar=no`.
  - The split off segment receives a unique synthetic way ID starting at 90,000,000,000 to prevent conflicts with upstream OSM IDs.
- **Unsplit Ways**: If the way does not meet the splitting criteria (e.g. snaps close to ends or has fewer than 3 nodes), the entire way is restricted with `motor_vehicle=no` and `microcar=no`.

## Point Snapping vs Corridor Propagation Rationale

BromBrom intentionally enforces **strict point-to-segment snapping** rather than automated graph-based corridor propagation for the following critical reasons:

1. **Absence of End-of-Zone Data in NDW**: NDW point data records C9 start signs, but does not track cancellation/end-of-zone signs. Automated downstream propagation cannot determine where a restriction legally ends (e.g. at built-up area boundaries, speed reductions to 50 km/h, or microcar access points).
2. **Junction & Side-Street Bleed**: Graph propagation across intersection nodes easily bleeds prohibitions onto open crossing roads, turning lanes, and connecting ramps.
3. **Parallel Road Name Collisions**: Parallel service roads, cycleways, and opposite carriageways often share identical road names (e.g. *Deldenerstraat*). Tracing by name or node connection leads to false-positive closures of accessible local service roads.
4. **Pre-Warning Amplification**: Propagating pre-warning C9 signs snapped to local urban feeder streets would incorrectly block municipal access roads before drivers ever reach the restricted highway.

**Design Consensus**: Point-to-segment snapping minimizes false-positive closures. For multi-segment highway corridors where physical signs only stand at entry points, upstream tagging in OpenStreetMap (`traffic_sign=NL:C9` or `microcar=no`) is the primary, safest mechanism to block all downstream segments.

