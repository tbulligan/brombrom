#!/usr/bin/env python3
import json
import os
import shutil
import zipfile
from pathlib import Path

def create_osmand_deploy_package():
    print("Building dist/BromBrom.osf package...")
    
    # Paths
    dist_dir = Path("dist")
    map_src = Path("OsmAndMapCreator/NL_BromBrom_tagged.obf")
    routing_src = Path("config/routing.xml")
    osf_path = dist_dir / "BromBrom.osf"
    
    dist_dir.mkdir(parents=True, exist_ok=True)
    
    if osf_path.exists():
        osf_path.unlink()

    # Custom OsmAnd profile JSON tailored for microcar navigation
    osmand_profile_json = {
      "force_private_access_routing": "false",
      "default_driving_region": "EUROPE_ASIA",
      "fuel_tank_capacity": "17.5",
      "default_speed": "12.5",
      "min_speed": "1.9444445",
      "max_speed": "12.5",
      "derived_profile": "default",
      "app_mode_version": "-1",
      "map_empty_state_allowed": "false",
      "view_angle_visibility": "RESTING",
      "location_radius_visibility": "RESTING_NAVIGATION",
      "interrupt_music": "false",
      "fast_route_mode": "true",
      "show_nearby_favorites": "false",
      "show_nearby_poi": "false",
      "rotate_map": "1",
      "audio_stream": "3",
      "selected_external_input_device": "keyboard",
      "custom_external_input_devices": "",
      "external_input_device_enabled": "true",
      "last_known_map_rotation": "-0.0",
      "last_known_map_elevation": "90.0",
      "renderer": "snowmobile",
      "nrenderer_appMode": "car",
      "osmand_theme": "2",
      "nrenderer_baseAppMode": "car",
      "nrenderer_contourLines": "13",
      "nrenderer_hideIcons": "true",
      "nrenderer_hidePOILabels": "true",
      "nrenderer_hideHouseNumbers": "true",
      "nrenderer_noAdminboundaries": "true",
      "nrenderer_hideUnderground": "true",
      "nrenderer_hideBuildings": "true",
      "OsmAnd (online tiles)_param_min": "0.0",
      "OsmAnd (online tiles)_param_max": "0.0",
      "OsmAnd (online tiles)_param_step": "0.0",
      "nrenderer_depthContours": "true",
      "show_next_turn_info": "true",
      "simple_widget_sizeroute_info": "MEDIUM",
      "route_info_widget_display_mode": "ARRIVAL_TIME",
      "route_info_widget_display_priority": "DESTINATION_FIRST",
      "prouting_allow_private": "false",
      "prouting_weight": "0.5",
      "prouting_height": "1.6",
      "prouting_length": "3.0",
      "prouting_width": "1.5",
      "prouting_motor_type": "2.0",
      "auto_follow_route": "5",
      "routing_recalc_distance": "30"
    }

    # OsmAnd items.json manifest
    items_manifest = {
      "version": 3,
      "items": [
        {
          "type": "FILE",
          "file": "/routing/routing.xml",
          "subtype": "routing_config"
        },
        {
          "type": "FILE",
          "file": "/NL_BromBrom_tagged.obf",
          "subtype": "obf_map"
        },
        {
          "type": "PROFILE",
          "file": "profile_brombrom.json",
          "appMode": {
            "customIconColor": -45024,
            "iconColor": "DEFAULT",
            "iconName": "mx_activities_car",
            "locIcon": "STATIC_CAR",
            "navIcon": "MOVEMENT_DEFAULT",
            "order": 13,
            "parent": "car",
            "routeService": "OSMAND",
            "routingProfile": "routing.xml/BromBrom",
            "stringKey": "brombrom",
            "userProfileName": "BromBrom",
            "version": -1
          }
        }
      ]
    }

    with zipfile.ZipFile(osf_path, 'w', zipfile.ZIP_DEFLATED) as osf_zip:
        
        # 1. Routing file inside '/routing' with far-future timestamp (2035-01-01) for priority override
        if not routing_src.exists():
            raise FileNotFoundError(f"Routing configuration file not found at {routing_src}")
        with open(routing_src, 'rb') as f:
            routing_data = f.read()
        routing_info = zipfile.ZipInfo("routing/routing.xml")
        routing_info.date_time = (2035, 1, 1, 0, 0, 0)
        routing_info.compress_type = zipfile.ZIP_DEFLATED
        osf_zip.writestr(routing_info, routing_data)
        print(f"  Added routing.xml")

        # 2. Map data at root with far-future timestamp (2035-01-01) for priority override
        if not map_src.exists():
            raise FileNotFoundError(f"OsmAnd OBF map file not found at {map_src}")
        with open(map_src, 'rb') as f:
            obf_data = f.read()
        obf_info = zipfile.ZipInfo("NL_BromBrom_tagged.obf")
        obf_info.date_time = (2035, 1, 1, 0, 0, 0)
        obf_info.compress_type = zipfile.ZIP_DEFLATED
        osf_zip.writestr(obf_info, obf_data)
        print(f"  Added NL_BromBrom_tagged.obf")

        # 3. Profile JSON
        osf_zip.writestr("profile_brombrom.json", json.dumps(osmand_profile_json, indent=2))
        print("  Added profile_brombrom.json")

        # 4. Items.json Manifest
        osf_zip.writestr("items.json", json.dumps(items_manifest, indent=2))
        print("  Added items.json manifest")

    print(f"✓ Deployment package ready: {osf_path}")

if __name__ == "__main__":
    create_osmand_deploy_package()
