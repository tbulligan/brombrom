#!/usr/bin/env python3
import os
import sys

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow (PIL) is not installed. Please install it using: pip install Pillow")
    sys.exit(1)

def generate_assets():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    assets_dir = os.path.join(project_root, "assets")
    logo_dir = os.path.join(assets_dir, "logos")

    # Paths
    src_logo = os.path.join(logo_dir, "brombrom-logo.jpg")
    src_banner = os.path.join(assets_dir, "brombrom-banner.png")
    
    dest_icon = os.path.join(assets_dir, "play_store_icon.png")
    dest_feature = os.path.join(assets_dir, "play_store_feature_graphic.png")

    # Check source files
    if not os.path.exists(src_logo):
        # Check alternative path if under app/assets
        src_logo = os.path.join(project_root, "app", "assets", "logos", "brombrom-logo.jpg")
        if not os.path.exists(src_logo):
            print(f"Error: Source logo not found at {src_logo}")
            sys.exit(1)

    if not os.path.exists(src_banner):
        print(f"Error: Source banner not found at {src_banner}")
        sys.exit(1)

    print(f"Loading logo from: {src_logo}")
    print(f"Loading banner from: {src_banner}")

    # 1. Generate Play Store Icon (512x512)
    try:
        # Determine resizing filter (Pillow v10+ uses Resampling.LANCZOS, older versions use Image.LANCZOS or Image.ANTIALIAS)
        try:
            resample_filter = Image.Resampling.LANCZOS
        except AttributeError:
            resample_filter = Image.ANTIALIAS

        img_logo = Image.open(src_logo)
        img_icon = img_logo.resize((512, 512), resample=resample_filter)
        img_icon.save(dest_icon, "PNG")
        print(f"Saved Play Store Icon (512x512) to: {dest_icon}")
    except Exception as e:
        print(f"Error generating play store icon: {e}")
        sys.exit(1)

    # 2. Generate Play Store Feature Graphic (1024x500 padded symmetrically with white background)
    try:
        img_banner = Image.open(src_banner)
        width, height = img_banner.size
        print(f"Source banner dimensions: {width}x{height}")

        # Target dimensions
        target_w, target_h = 1024, 500

        # Create a new white image of target dimensions
        new_banner = Image.new("RGB", (target_w, target_h), (255, 255, 255))

        # Calculate position to paste (symmetrically centered vertically, aligned horizontally)
        x_offset = 0
        y_offset = (target_h - height) // 2

        new_banner.paste(img_banner, (x_offset, y_offset))
        new_banner.save(dest_feature, "PNG")
        print(f"Saved Feature Graphic (1024x500) to: {dest_feature}")
    except Exception as e:
        print(f"Error generating play store feature graphic: {e}")
        sys.exit(1)

    print("Success: Google Play assets generated successfully!")

if __name__ == "__main__":
    generate_assets()
