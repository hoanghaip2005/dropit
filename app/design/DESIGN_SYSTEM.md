# DropIt! — control refresh, 2026-10-22

The requested brand refresh supersedes the black action/navigation treatment in the original mockups. Shared tokens in `lib/core/theme/tokens.dart` are the source of truth: warm cream canvas, white cards, terracotta brand actions, warm brown text, sand borders. Green remains success; red remains destructive/error. Lockdown retains its separate static dark palette.

Actions use 16px rounded corners and 48/56px heights. Filters use a soft brand fill, outline, visible checkmark and selected semantics, with at least 44px height. Navigation uses white with soft brand selection for both roles. Checkbox, radio, switch, segmented controls, icon buttons, date/time controls, input focus and progress share the brand palette. Disabled buttons use sand and muted text; loading buttons retain a readable brand spinner treatment.

Six title emblems and three achievement families were generated through Krita AI Diffusion Cloud (`zavychromaxl_v80.safetensors`), not Blender. Original art and exact prompts live in `design/frames_ai/<key>/`. `scripts/redesign_emblems_ai.ps1` generates them; `scripts/prepare_emblems_ai.py` removes connected backgrounds and exports 512px PNGs. Titles use light tinted plates with dark readable live labels. Achievement milestones remain live text with tier stars; the 13 thresholds, progress, earned status and privacy rules are unchanged.

Validation includes text contrast, filter selection/disabled-action behavior, existing feature tests and Flutter analysis. Local previews use `python scripts/serve_web.py` after a web build to avoid stale service workers and asset cache.

## Stitch layout alignment

Read directly from project `2723223813529979616`: The Shop (`f4e4f5f3b5ba4bde91664e19e7c3b2f7`), User Profile (`973c5f1448634ef48a45a4ce7525a858`), and T-02 group list (`ef8748bdc11b4c0391735eb01a463747`). These coexist with older variants; project-level dark theme metadata is not a blanket instruction to recolor the app.

Shop, groups and profile use the same caption + page-title header hierarchy. Shop artwork sits on a separate inset canvas, with shorter title cards and a responsive grid. Group completion uses a dedicated inset panel, prominent percentage and progress bar, scoped to the existing per-group metric. Current content, privacy, navigation routes and approved artwork take precedence over obsolete sample copy or features from Stitch.

The group list places Create and Join side by side, followed by the group count. Each 24px-radius card has a group icon, name, member count, role, inset completion panel, calendar row and explicit View Group action. Owners additionally see Schedule. Existing suspended/dissolving status remains visible; no aggregate completion or invented member avatars are displayed.
