# 2D AI avatar frames

Eight original concepts generated through the existing Krita AI Diffusion Cloud account, `zavychromaxl_v80.safetensors`, 1024×1024, 28 steps. Each directory contains the full prompt and sampler settings (`prompt.json`), original image, transparent export, and previous runtime artwork for comparison.

Generate: `app/scripts/redesign_frames_ai.ps1`. This uses cloud credits and skips completed output files. Prepare transparent overlays: `python app/scripts/prepare_frames_ai.py`. Preparation removes neutral/gradient backdrops, clears a consistent central aperture, removes square corner ornaments, then scales to the existing avatar overlay. Runtime PNGs remain 768×768.

The approved Sakura AI frame is retained separately at `app/design/sakura_ai`; its runtime asset is unchanged by these scripts. Existing prices, item IDs and ownership are unchanged. Blender scripts can overwrite PNGs; rerun the preparation scripts to restore AI artwork afterwards.
