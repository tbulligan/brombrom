import time
import pandas as pd
import numpy as np
import geopandas as gpd
from scripts.snap_c9_to_roads import has_microcar_exemption
from shapely.geometry import Point
import sys

# Generate some mock data
n = 100000
data = {
    'textSigns': np.random.choice([
        'brommobielen toegestaan',
        'geen brommobielen',
        'uitgezonderd brommo',
        'ob65',
        'verboden',
        '',
        None,
        'fietsers toegestaan',
        'brommobielen m.u.v.',
        'uitgezonderd brommoblelen'
    ], size=n)
}
geometry = [Point(0, 0) for _ in range(n)]

c9_gdf = gpd.GeoDataFrame(data, geometry=geometry)

def original_code():
    global c9_gdf
    df = c9_gdf.copy()
    start = time.time()

    exempt = df[df.apply(has_microcar_exemption, axis=1)]
    exempt_len = len(exempt)

    df = df[~df.apply(has_microcar_exemption, axis=1)]
    df_len = len(df)

    end = time.time()
    return end - start

def optimized_code():
    global c9_gdf
    df = c9_gdf.copy()
    start = time.time()

    mask = df.apply(has_microcar_exemption, axis=1)
    exempt = df[mask]
    exempt_len = len(exempt)

    df = df[~mask]
    df_len = len(df)

    end = time.time()
    return end - start

orig_time = sum(original_code() for _ in range(3)) / 3
opt_time = sum(optimized_code() for _ in range(3)) / 3

print(f"Original: {orig_time:.4f} seconds")
print(f"Optimized: {opt_time:.4f} seconds")
print(f"Speedup: {orig_time / opt_time:.2f}x")
