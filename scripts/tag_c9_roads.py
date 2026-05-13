import geopandas as gpd
import os
import osmium

class TagC9Handler(osmium.SimpleHandler):
    def __init__(self, writer, forbidden_ways):
        super().__init__()
        self.writer = writer
        self.forbidden_ways = forbidden_ways

    def node(self, n):
        # forward all nodes unchanged
        self.writer.add_node(n)

    def relation(self, r):
        # forward all relations unchanged
        self.writer.add_relation(r)

    def way(self, w):
        modified = False
        microcar = w.tags.get('microcar')
        motor_vehicle = w.tags.get('motor_vehicle')
        
        # 1. Existing OSM Coverage: Promote 'microcar=no' to 'motor_vehicle=no'
        # This ensures OsmAnd (which mainly looks at motor_vehicle) respects these.
        if microcar == 'no' and motor_vehicle != 'no':
            modified = True

        # 2. NDW Pipeline Coverage: Tag ways identified as C9-forbidden
        if int(w.id) in self.forbidden_ways:
            if motor_vehicle != 'no' or microcar != 'no':
                modified = True
            
        if modified:
            tags = dict(w.tags)
            if microcar == 'no' and motor_vehicle != 'no':
                tags['motor_vehicle'] = 'no'
            if int(w.id) in self.forbidden_ways:
                tags['motor_vehicle'] = 'no'
                tags['microcar'] = 'no'
            w = w.replace(tags=tags)

        self.writer.add_way(w)

def main():
    if os.path.exists("NL_BromBrom_tagged.osm.pbf"):
        print("NL_BromBrom_tagged.osm.pbf already exists. Skipping.")
        return

    gdf = gpd.read_file("nl_roads_brom.gpkg")
    print(f"Loaded {len(gdf)} C9-forbidden roads")

    forbidden_ways = set()
    id_fields = ['osm_id', 'id', 'OSM_ID']
    for field in id_fields:
        if field in gdf.columns:
            forbidden_ways = set(gdf[field].dropna().astype(int).unique())
            print(f"Using '{field}' with {len(forbidden_ways)} unique ways")
            break

    if not forbidden_ways:
        raise ValueError("No valid OSM ID field found")

    print("Tagging OSM PBF...")
    with osmium.SimpleWriter("NL_BromBrom_tagged.osm.pbf", overwrite=True) as writer:
        handler = TagC9Handler(writer, forbidden_ways)
        # Optimization: Use the filtered roads-only PBF as base (huge RAM saving)
        handler.apply_file("nl_roads.osm.pbf")
    print(f"✓ NL_BromBrom_tagged.osm.pbf created ({len(forbidden_ways)} C9 ways tagged)")

if __name__ == "__main__":
    main()
