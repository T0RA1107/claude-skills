"""Render a BEAT2 SMPL-X npz file to video using emage_utils/fast_render.py."""

import argparse
import os
from pathlib import Path

# Must be set before emage_utils is imported, as it reads this env var at load time.
os.environ["PYOPENGL_PLATFORM"] = "egl"

from emage_utils.fast_render import (
    render_one_sequence_no_gt,
    render_one_sequence_with_face,
)

def parse_args() -> argparse.Namespace:
    """Parse command-line arguments for the BEAT2 renderer.

    Returns:
        Parsed argument namespace.
    """
    parser = argparse.ArgumentParser(
        description="Render a BEAT2 SMPL-X .npz file to video."
    )
    parser.add_argument("npz_path", help="Path to BEAT2 smplxflame_30 .npz file")
    parser.add_argument("--audio", default=None, help="Path to audio .wav file")
    parser.add_argument(
        "--output_dir",
        default=None,
        help="Output directory (default: <npz_dir>/render_out)",
    )
    parser.add_argument(
        "--model_folder",
        default=".",
        help="SMPL-X model folder (default: project root)",
    )
    parser.add_argument(
        "--no_transl",
        action="store_true",
        default=True,
        help="Remove translation (default: True)",
    )
    parser.add_argument(
        "--with_face",
        action="store_true",
        default=False,
        help="Use face expression rendering",
    )
    return parser.parse_args()


def main() -> None:
    """Entry point: resolve paths and invoke renderer."""
    args = parse_args()

    npz_path = Path(args.npz_path).resolve()
    output_dir = (
        Path(args.output_dir) if args.output_dir else npz_path.parent / "render_out"
    )
    output_dir.mkdir(parents=True, exist_ok=True)

    render_kwargs = dict(
        res_npz_path=str(npz_path),
        output_dir=str(output_dir),
        audio_path=args.audio,
        model_folder=args.model_folder,
        remove_transl=args.no_transl,
    )

    if args.with_face:
        out = render_one_sequence_with_face(**render_kwargs)
    else:
        out = render_one_sequence_no_gt(**render_kwargs)

    print(f"Output: {out}")


if __name__ == "__main__":
    main()
