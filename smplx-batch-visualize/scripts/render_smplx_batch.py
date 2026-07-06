"""Batch-render SMPL-X sequences (sam-body4d format) to videos.

Walks a root directory for `smplx_params.npz` files and renders each to an mp4
using PantoMatrix's `emage_utils.fast_render`. The npz layout produced by
sam-body4d's mhr2smplx stage is:
    betas       (300,)
    poses       (N, 165)
    expressions (N, 100)
    trans       (N, 3)
which is directly compatible with the renderer.

`render_one_sequence_no_gt` computes `seconds = N // 30`, which floors short
clips (N < 30) to an empty video. We drive the SMPL-X model and the silent
video writer here with the true frame count `N` to avoid that.
"""

import argparse
import os
from pathlib import Path

# Must be set before emage_utils is imported.
os.environ["PYOPENGL_PLATFORM"] = "egl"

import numpy as np
import torch
import smplx

from emage_utils.fast_render import generate_silent_videos_no_gt


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Batch-render sam-body4d SMPL-X .npz sequences to videos."
    )
    parser.add_argument(
        "root",
        help="Directory to search recursively for smplx_params.npz files.",
    )
    parser.add_argument(
        "--pattern",
        default="**/smplx_params.npz",
        help="Glob (relative to root) for npz files (default: **/smplx_params.npz).",
    )
    parser.add_argument(
        "--model_folder",
        default="/home/aolab/Desktop/PantoMatrix",
        help="SMPL-X model folder containing smplx/SMPLX_NEUTRAL_2020.npz.",
    )
    parser.add_argument(
        "--out_name",
        default="smplx_render.mp4",
        help="Output video filename, written next to each npz's gesture dir.",
    )
    parser.add_argument(
        "--freeze_transl",
        dest="freeze_transl",
        action="store_true",
        default=True,
        help="Freeze translation at the first frame (default: True).",
    )
    parser.add_argument(
        "--no_freeze_transl",
        dest="freeze_transl",
        action="store_false",
        help="Keep the original per-frame translation instead of freezing it.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Re-render even if the output video already exists.",
    )
    parser.add_argument(
        "--no_flat_hand_mean",
        dest="flat_hand_mean",
        action="store_false",
        default=False,
        help=argparse.SUPPRESS,  # default already False (BEAT2 convention)
    )
    parser.add_argument(
        "--flat_hand_mean",
        dest="flat_hand_mean",
        action="store_true",
        help="Treat saved hand poses as absolute (flat-hand basis). Default False "
             "matches the BEAT2/EMAGE convention used by PantoMatrix.",
    )
    return parser.parse_args()


def output_path_for(npz_path: Path, out_name: str) -> Path:
    """Place the video at the gesture root.

    For sam-body4d layout <gesture>/smplx/<pid>/smplx_params.npz we hop up to
    <gesture>; otherwise we drop the video beside the npz.
    """
    parent = npz_path.parent
    gesture_dir = parent.parent.parent if parent.parent.name == "smplx" else parent
    return gesture_dir / out_name


def build_model(model_folder: str, flat_hand_mean: bool = False):
    """Create the SMPL-X model once; it is independent of betas and frame count.

    flat_hand_mean=False matches the BEAT2/EMAGE convention used throughout
    PantoMatrix (see emage_utils/npz2pose.py): stored hand poses are deltas
    from the MANO mean, which the model adds back at forward time.
    """
    return smplx.create(
        model_folder, model_type="smplx", gender="NEUTRAL_2020",
        use_face_contour=False, num_betas=300, num_expression_coeffs=100,
        ext="npz", use_pca=False, flat_hand_mean=flat_hand_mean,
    ).cuda()


def render(npz_path: Path, out_path: Path, model, faces, freeze_transl: bool) -> int:
    with np.load(npz_path, allow_pickle=True) as data:
        betas = data["betas"]
        poses = data["poses"]
        expressions = data["expressions"]
        trans = data["trans"]
    n = int(poses.shape[0])

    beta = torch.from_numpy(betas).float().unsqueeze(0).cuda().repeat(n, 1)
    expression = torch.from_numpy(expressions[:n]).float().cuda()
    pose = torch.from_numpy(poses[:n]).float().cuda()
    jaw_pose = pose[:, 66:69]
    transl = torch.from_numpy(trans[:n]).float().cuda()
    if freeze_transl:
        transl = transl[0:1].repeat(n, 1)

    with torch.no_grad():
        output = model(
            betas=beta, transl=transl, expression=expression, jaw_pose=jaw_pose,
            global_orient=pose[:, :3], body_pose=pose[:, 3:21 * 3 + 3],
            left_hand_pose=pose[:, 25 * 3:40 * 3],
            right_hand_pose=pose[:, 40 * 3:55 * 3],
            leye_pose=pose[:, 69:72], reye_pose=pose[:, 72:75], return_verts=True,
        )
    vertices_all = output["vertices"].cpu().numpy()

    out_path.parent.mkdir(parents=True, exist_ok=True)
    sfile = generate_silent_videos_no_gt(n, vertices_all, faces, str(out_path.parent))
    os.replace(sfile, out_path)
    return n


def main() -> None:
    args = parse_args()
    root = Path(args.root).resolve()
    npz_paths = sorted(root.glob(args.pattern))
    print(f"Found {len(npz_paths)} sequences under {root}")
    if not npz_paths:
        return

    # Model and faces are constant across the batch; build them once.
    model = build_model(args.model_folder, args.flat_hand_mean)
    faces = np.load(
        f"{args.model_folder}/smplx/SMPLX_NEUTRAL_2020.npz", allow_pickle=True
    )["f"]

    rendered = 0
    for npz_path in npz_paths:
        out_path = output_path_for(npz_path, args.out_name)
        rel = npz_path.relative_to(root)
        if out_path.exists() and not args.overwrite:
            print(f"[skip] {rel} (exists: {out_path.name})")
            continue
        n = render(npz_path, out_path, model, faces, args.freeze_transl)
        print(f"[done] {rel} -> {out_path} ({n} frames)")
        rendered += 1

    print(f"Rendered {rendered}/{len(npz_paths)} sequences.")


if __name__ == "__main__":
    main()
