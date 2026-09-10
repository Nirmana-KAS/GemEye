import os
import sys

"""
GemEye Dataset Image Auto-Renamer

Renames all images in the dataset folders to a consistent format:
  raw_by_shape: {shape}_{grade}_{NNN}.jpg  (e.g., baguette_g1_001.jpg)
  merged:       {grade}_{NNN}.jpg          (e.g., g3_001.jpg)
  ccc_patches:  no change (already named correctly)

Usage:
  python rename_images.py raw       # rename raw_by_shape images
  python rename_images.py merged    # rename merged images
  python rename_images.py all       # rename both
"""

SHAPES = ['baguette', 'oval', 'pear', 'round']
GRADES = ['grade_1', 'grade_2', 'grade_3', 'grade_4', 'grade_5', 'grade_6', 'grade_7']
IMAGE_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.heic', '.webp'}

def rename_raw_by_shape():
    base = os.path.join(os.path.dirname(__file__), 'raw_by_shape')
    if not os.path.exists(base):
        print(f"Folder not found: {base}")
        return

    total = 0
    for shape in SHAPES:
        for grade in GRADES:
            folder = os.path.join(base, shape, grade)
            if not os.path.exists(folder):
                print(f"  Skipping (not found): {shape}/{grade}")
                continue

            files = sorted([
                f for f in os.listdir(folder)
                if os.path.splitext(f)[1].lower() in IMAGE_EXTENSIONS
            ])

            grade_num = grade.split('_')[1]

            # First pass: rename to temp names to avoid conflicts
            for i, filename in enumerate(files):
                ext = os.path.splitext(filename)[1].lower()
                if ext == '.jpeg':
                    ext = '.jpg'
                temp_name = f"_temp_{i:04d}{ext}"
                os.rename(os.path.join(folder, filename), os.path.join(folder, temp_name))

            # Second pass: rename to final names
            temp_files = sorted([f for f in os.listdir(folder) if f.startswith('_temp_')])
            for i, filename in enumerate(temp_files):
                ext = os.path.splitext(filename)[1].lower()
                new_name = f"{shape}_g{grade_num}_{i+1:03d}{ext}"
                os.rename(os.path.join(folder, filename), os.path.join(folder, new_name))
                total += 1

            print(f"  Renamed {len(temp_files):3d} images in {shape}/{grade} -> {shape}_g{grade_num}_001.jpg ...")

    print(f"\nTotal raw_by_shape images renamed: {total}")


def rename_merged():
    base = os.path.join(os.path.dirname(__file__), 'merged')
    if not os.path.exists(base):
        print(f"Folder not found: {base}")
        return

    total = 0
    merged_folders = sorted([
        d for d in os.listdir(base)
        if os.path.isdir(os.path.join(base, d)) and d.startswith('grade_')
    ])

    for folder_name in merged_folders:
        folder = os.path.join(base, folder_name)

        files = sorted([
            f for f in os.listdir(folder)
            if os.path.splitext(f)[1].lower() in IMAGE_EXTENSIONS
        ])

        grade_num = folder_name.split('_')[1]

        # First pass: temp names
        for i, filename in enumerate(files):
            ext = os.path.splitext(filename)[1].lower()
            if ext == '.jpeg':
                ext = '.jpg'
            temp_name = f"_temp_{i:04d}{ext}"
            os.rename(os.path.join(folder, filename), os.path.join(folder, temp_name))

        # Second pass: final names
        temp_files = sorted([f for f in os.listdir(folder) if f.startswith('_temp_')])
        for i, filename in enumerate(temp_files):
            ext = os.path.splitext(filename)[1].lower()
            new_name = f"g{grade_num}_{i+1:03d}{ext}"
            os.rename(os.path.join(folder, filename), os.path.join(folder, new_name))
            total += 1

        print(f"  Renamed {len(temp_files):3d} images in {folder_name} -> g{grade_num}_001.jpg ...")

    print(f"\nTotal merged images renamed: {total}")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python rename_images.py [raw|merged|all]")
        sys.exit(1)

    mode = sys.argv[1].lower()

    print("=" * 50)
    print("GemEye Dataset Image Renamer")
    print("=" * 50)

    if mode in ('raw', 'all'):
        print("\n--- Renaming raw_by_shape ---")
        rename_raw_by_shape()

    if mode in ('merged', 'all'):
        print("\n--- Renaming merged ---")
        rename_merged()

    print("\n" + "=" * 50)
    print("Done! Verify file counts match expected:")
    print("  raw_by_shape: 4 shapes x 7 grades x 40 = 1,120")
    print("  merged: 7 grades x 160 = 1,120")
    print("=" * 50)
