---
name: beat2-visualize
description: Render BEAT2 format SMPL-X motion data (.npz) to video using emage_utils/fast_render.py. Works with files in BEAT2/*/smplxflame_30/.
---

# BEAT2 Visualize Skill

## Purpose
Render BEAT2 SMPL-X motion data (.npz files) to video using `emage_utils/fast_render.py`.

## Inputs
Accept the following from the user:
- **npz_path** (required): Path to a .npz file under BEAT2's `smplxflame_30/` directory.
  - Example: `BEAT2/beat_english_v2.0.0/smplxflame_30/10_kieks_0_1_1.npz`
- **audio_path** (optional): Path to the corresponding audio file. If omitted, automatically search the speaker's `wave16k/` directory.
- **output_dir** (optional): Output directory. If omitted, creates `render_out/` next to the npz file.
- **--with_face** (optional): Include facial expression rendering.

## Workflow

### 1. Resolve Arguments
- Verify the npz path and convert it to an absolute path.
- If `audio_path` is not provided: extract the speaker ID and file ID from the npz filename and locate the corresponding `.wav` under `wave16k/`.
  - Example: `smplxflame_30/10_kieks_0_1_1.npz` → `wave16k/10_kieks_0_1_1.wav`

### 2. Run Renderer
Execute the following from the project root (`/home/aolab/Desktop/PantoMatrix`):

```bash
/home/aolab/Desktop/PantoMatrix/.venv/bin/python /home/aolab/.claude/skills/beat2-visualize/scripts/render_beat2.py \
  <npz_path> \
  [--audio <audio_path>] \
  [--output_dir <output_dir>] \
  [--model_folder /home/aolab/Desktop/PantoMatrix] \
  [--with_face]
```

**Important**: Always use the absolute path `/home/aolab/Desktop/PantoMatrix/.venv/bin/python`. Never use `python3`, `python`, or any other `.venv` — only this virtualenv has `emage_utils` and the required dependencies installed.

### 3. Report Results
- Report the path of the generated video to the user.
- If an error occurs, inspect stderr and report the cause.

## Notes
- `--model_folder .` points to the project root, where `./smplx/SMPLX_NEUTRAL_2020.npz` resides.
- Rendering requires CUDA; insufficient GPU memory will cause an error.
- `mocap_frame_rate` is 30 fps, so this skill is optimized for data under `smplxflame_30/`.
- Translation is frozen by default (position is fixed at the first frame).
