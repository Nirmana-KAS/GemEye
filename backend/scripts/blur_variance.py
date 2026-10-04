"""Prints the server's blur variance (app.pipeline.inference.blur_variance) for image
files, decoded exactly as /grade decodes uploads. Development only: used to make the
reference values of the app's Photo Check unit test (app/test/photo_check_test.dart).

    docker compose exec api python scripts/blur_variance.py /srv/tests/_tmp/a.png ..."""
import argparse
import sys

sys.path.insert(0, ".")
from app.config import get_settings  # noqa: E402
from app.gates import BLUR_MIN_VARIANCE  # noqa: E402
from app.pipeline.colour import decode_image  # noqa: E402
from app.pipeline.inference import blur_variance  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description="Print the server blur variance of images.")
    parser.add_argument("files", nargs="+")
    args = parser.parse_args()
    if get_settings().is_production:
        sys.exit("Refusing to run with ENV=production.")
    print(f"# threshold {BLUR_MIN_VARIANCE!r}")
    for path in args.files:
        with open(path, "rb") as f:
            rgb = decode_image(f.read())
        h, w = rgb.shape[:2]
        print(f"{path}\t{w}x{h}\t{blur_variance(rgb)!r}")


if __name__ == "__main__":
    main()
