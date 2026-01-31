# Enhanced Snapping Logic

## Challenge
NDW C9 traffic signs often lack explicit compass bearings, but provide a `side` attribute which can be:
- Cardinal: `N`, `O`, `Z`, `W` (Reliable, mapped to degrees)
- Relative: `L` (Left), `R` (Right) (Ambiguous without road context)

Signs with `L`/`R` side usage (~30% of dataset) were previously falling back to "Distance Only" snapping, which is error-prone in dense areas or near intersections.

## Solution: Geometric Side Matching
We implemented a geometric side detection algorithm in `snap_c9_to_roads.py`.

### Algorithm
1. Project the sign point onto the candidate road segment.
2. Determine the vector of the road at the projection point.
3. Calculate the **2D Cross Product** of the road vector and the vector to the sign.
4. Determine if the sign lies geometrically to the **Left** or **Right** of the road.
5. **Score Boost**:
   - If `Sign.Side == Geometric.Side`: Apply a score bonus (equivalent to being 5m closer).
   - If `Sign.Side != Geometric.Side`: Apply a score penalty (equivalent to being 10m further).

### Impact
This ensures that a "Right" sign snaps to the road where it is physically on the right, distinguishing between:
- Parallel roads
- Dual carriageways
- Intersecting roads (where the sign position favors one alignment)

This dramatically reduces "False Positives" on adjacent but irrelevant roads.
