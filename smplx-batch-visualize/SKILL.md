---
name: smplx-batch-visualize
description: Batch-render sam-body4d SMPL-X motion outputs (smplx_params.npz) to videos by recursively searching a directory. Use for output trees like TurboDiffusion/output/*/<name>/smplx/<pid>/smplx_params.npz produced by sam-body4d's mhr2smplx stage.
---

# SMPL-X Batch Visualize Skill

## Purpose
Render many sam-body4d SMPL-X sequences to video in one pass. Given a root
directory, it finds every `smplx_params.npz` and writes one mp4 per sequence.

Unlike `beat2-visualize` (single file, BEAT2 layout), this skill is for batch
processing of sam-body4d outputs and handles short clips (N < 30 frames)
correctly — the upstream `render_one_sequence_no_gt` floors `seconds = N // 30`
and would emit empty videos for them.

## Inputs
- **root** (required): Directory searched recursively for `smplx_params.npz`.
  - Example: `/home/aolab/Desktop/TurboDiffusion/output/gestures_fixed_smplx`
- **--pattern** (optional): Glob relative to root (default `**/smplx_params.npz`).
- **--out_name** (optional): Output filename per gesture dir (default `smplx_render.mp4`).
- **--model_folder** (optional): SMPL-X model folder (default `/home/aolab/Desktop/PantoMatrix`,
  which holds `smplx/SMPLX_NEUTRAL_2020.npz`).
- **--overwrite** (optional): Re-render even if the output already exists.
- **--no_freeze_transl** (optional): Keep the original per-frame translation
  instead of freezing it at frame 0 (default is frozen / in-place motion).
- **--flat_hand_mean** (optional): Treat saved hand poses as absolute (flat-hand
  basis). **Default is False** to match the BEAT2/EMAGE convention (hand poses
  are deltas from the MANO mean, added back at forward time). Only pass this if
  the npz was produced with `flat_hand_mean=True`. A mismatch between the npz's
  basis and this flag double-counts the MANO mean (~0.26 rad/joint) and renders
  hands fist-like — this was the original "hands look like a fist" bug.

## npz format (sam-body4d mhr2smplx)
```
betas       (300,)      float
poses       (N, 165)    axis-angle, 55 joints
expressions (N, 100)    float
trans       (N, 3)      float (frozen to frame 0 by default)
```

## Output placement
For the sam-body4d layout `<gesture>/smplx/<pid>/smplx_params.npz`, the video is
written to `<gesture>/<out_name>`. Otherwise it is written next to the npz.

## Workflow

### 1. Resolve the root and confirm scope
Verify the root exists and report how many `smplx_params.npz` will be rendered
before running a long batch.

### 2. Run the batch renderer
Always use PantoMatrix's venv — only it has `emage_utils`, `smplx`, and CUDA deps:

```bash
/home/aolab/Desktop/PantoMatrix/.venv/bin/python \
  /home/aolab/.claude/skills/smplx-batch-visualize/scripts/render_smplx_batch.py \
  <root> \
  [--pattern '**/smplx_params.npz'] \
  [--out_name smplx_render.mp4] \
  [--model_folder /home/aolab/Desktop/PantoMatrix] \
  [--overwrite]
```

Rendering uses CUDA and multiprocessing; run from a machine with a free GPU.
For large batches, prefer running in the background and reporting progress.

### 3. Report results
Report how many sequences were rendered and where the videos landed. On error,
inspect stderr and report the cause (common: GPU OOM, missing SMPL-X model file).

## Notes
- Output fps is 30 (`emage_utils.fast_render` default); short clips yield short videos.
- Translation is frozen at the first frame by default (in-place motion).
- No audio is added (motion-only silent video).
