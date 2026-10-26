# Sakura AI concept

Generated using the existing Krita AI Diffusion cloud connection (Interstice), checkpoint `zavychromaxl_v80.safetensors`, 1024×1024, one image. Prompt and sampling settings: `prompt.json`.

`sakura-ai-original.png` is the unmodified AI result with an opaque background.

`app/scripts/prepare_sakura_ai.py` removes the connected neutral background and blank center, scales the artwork to the existing avatar overlay, and exports `sakura-ai-transparent.png`. The runtime asset `assets/cosmetics/frame_sakura.png` now uses this AI artwork. Shop identity, ownership and price are preserved.
