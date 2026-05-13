import time
import os
import tempfile
import osmium

# Mock simple writer
class MockWriter:
    def add_way(self, w):
        pass

class OldTagC9Handler(osmium.SimpleHandler):
    def __init__(self, writer, forbidden_ways):
        super().__init__()
        self.writer = writer
        self.forbidden_ways = forbidden_ways
        self.count = 0

    def way(self, w):
        tags = dict(w.tags)
        modified = False
        if tags.get('microcar') == 'no' and tags.get('motor_vehicle') != 'no':
            tags['motor_vehicle'] = 'no'
            modified = True
        if int(w.id) in self.forbidden_ways:
            if tags.get('motor_vehicle') != 'no' or tags.get('microcar') != 'no':
                tags['motor_vehicle'] = 'no'
                tags['microcar'] = 'no'
                modified = True
        if modified:
            w = w.replace(tags=tags)
        self.writer.add_way(w)
        self.count += 1

class NewTagC9Handler(osmium.SimpleHandler):
    def __init__(self, writer, forbidden_ways):
        super().__init__()
        self.writer = writer
        self.forbidden_ways = forbidden_ways
        self.count = 0

    def way(self, w):
        modified = False
        microcar = w.tags.get('microcar')
        motor_vehicle = w.tags.get('motor_vehicle')

        if microcar == 'no' and motor_vehicle != 'no':
            modified = True

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
        self.count += 1

def main():
    # create a small test file
    with open('test.osm', 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n<osm version="0.6" generator="test">\n')
        for i in range(1, 100000):
            f.write(f'<node id="{i}" lat="0" lon="0" />\n')
            f.write(f'<way id="{i}">\n')
            f.write(f'  <nd ref="{i}"/>\n')
            f.write(f'  <tag k="highway" v="residential"/>\n')
            f.write(f'  <tag k="name" v="Street {i}"/>\n')
            f.write(f'</way>\n')
        f.write('</osm>\n')

    forbidden = set([10, 20, 30])

    # Baseline
    t0 = time.time()
    for _ in range(10): # run 10 times to get measurable time
        h1 = OldTagC9Handler(MockWriter(), forbidden)
        h1.apply_file("test.osm")
    t1 = time.time()
    old_time = t1 - t0

    # Optimized
    t0 = time.time()
    for _ in range(10):
        h2 = NewTagC9Handler(MockWriter(), forbidden)
        h2.apply_file("test.osm")
    t1 = time.time()
    new_time = t1 - t0

    print(f"Old time: {old_time:.3f}s")
    print(f"New time: {new_time:.3f}s")
    print(f"Improvement: {(old_time - new_time)/old_time*100:.1f}%")

if __name__ == "__main__":
    main()
