---
name: DropIt!
colors:
  surface: '#fdf8f8'
  surface-dim: '#ddd9d9'
  surface-bright: '#fdf8f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f7f3f2'
  surface-container: '#f1edec'
  surface-container-high: '#ebe7e7'
  surface-container-highest: '#e5e2e1'
  on-surface: '#1c1b1b'
  on-surface-variant: '#46464a'
  inverse-surface: '#313030'
  inverse-on-surface: '#f4f0ef'
  outline: '#77767b'
  outline-variant: '#c7c6ca'
  surface-tint: '#5f5e60'
  primary: '#010102'
  on-primary: '#ffffff'
  primary-container: '#1c1c1e'
  on-primary-container: '#858486'
  inverse-primary: '#c8c6c8'
  secondary: '#c2410c'
  on-secondary: '#ffffff'
  secondary-container: '#ff7a00'
  on-secondary-container: '#141414'
  tertiary: '#010100'
  on-tertiary: '#ffffff'
  tertiary-container: '#1f1b1a'
  on-tertiary-container: '#8a8381'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e4e2e4'
  primary-fixed-dim: '#c8c6c8'
  on-primary-fixed: '#1b1b1d'
  on-primary-fixed-variant: '#474649'
  secondary-fixed: '#ffdbd1'
  secondary-fixed-dim: '#ffb5a0'
  on-secondary-fixed: '#3b0900'
  on-secondary-fixed-variant: '#862200'
  tertiary-fixed: '#eae0de'
  tertiary-fixed-dim: '#cdc5c3'
  on-tertiary-fixed: '#1f1b1a'
  on-tertiary-fixed-variant: '#4b4644'
  background: '#F4F5F7'
  on-background: '#1c1b1b'
  surface-variant: '#e5e2e1'
  card: '#FFFFFF'
  accent: '#C2410C'
  accent-fill: '#FF7A00'
  on-accent-fill: '#141414'
  accent-soft-bg: '#FFF3E8'
  accent-decor: '#FF7A00'
  brand-ink: '#141414'
  success: '#1B7F3B'
  success-decor: '#34C759'
  text-primary: '#111111'
  text-secondary: '#6C6C70'
  warning: '#BA1A1A'
  lockdown-bg: '#000000'
  lockdown-button: '#5C5C5C'
  lockdown-text-secondary: '#A1A1A6'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 18px
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 30px
  headline-xl-mobile:
    fontFamily: Inter
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 36px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes a clean, utilitarian aesthetic inspired by modern food delivery apps—blending high-end Apple-like smoothness with stark, confident contrasts. The brand personality is professional yet energetic, driving office productivity and focus through simple, non-competitive rewards (Coins for cosmetic items only). 

### Core Style: High-Contrast Minimalism with Tactile Depth
- **Aesthetic:** Uncluttered surfaces, heavy reliance on whitespace, stark matte black structural elements, and vibrant accent punches.
- **Emotional Response:** Focus, reliability, and playful reward anticipation.
- **Visual Distinction:** Pure white floating cards layered over an off-white canvas, anchored by stark black primary actions and vibrant tomato orange highlights.

## Colors

The palette is strictly calibrated to create maximum hierarchy and functional clarity. The base utilizes an off-white canvas (`#F4F5F7`) that allows pristine white cards (`#FFFFFF`) to float effortlessly. Matte black (`#1C1C1E`) commands primary actions and structural navigation, while the brand orange family (matching the app icon tray `#FFB300`→`#FF6A00`) marks currency and active states: bright `#FF7A00` as a fill, deep `#C2410C` for text/icons on light surfaces.

- **Primary:** Matte Black (`#1C1C1E`)
- **Accent fill (buttons, solid chips):** Brand Orange `#FF7A00` with **black `#141414` label** (7.05:1). White on `#FF7A00` = 2.61:1 — forbidden.
- **Accent (text, icons, Coins on light):** Deep Orange `#C2410C`. `#FF7A00` is never text on light backgrounds (2.45:1 on `#FAF7F3`).
- **Brand ink:** `#141414` (icon background, splash).
- **Neutral Canvas:** Off-White (`#F4F5F7`) & Pure White (`#FFFFFF`)
- **Functional:** Success Green text `#1B7F3B` (`#34C759` decorative only) and Warning Red `#BA1A1A`.
- **Rule:** Warning red is reserved for errors/exit alerts. It is **never** used as the accent color for Coins, rewards or highlights.

### Contrast table (WCAG 2.1, computed 2026-10-19; accent rows recomputed 2026-10-26)

| Pair | Ratio | Target |
| --- | --- | --- |
| text-primary `#111111` on background `#F4F5F7` | 17.31:1 | ≥4.5 |
| text-secondary `#6C6C70` on background `#F4F5F7` | 4.79:1 | ≥4.5 |
| text-secondary `#6C6C70` on card `#FFFFFF` | 5.23:1 | ≥4.5 |
| accent `#C2410C` on card `#FFFFFF` | 5.18:1 | ≥4.5 |
| accent `#C2410C` on app background `#FAF7F3` | 4.85:1 | ≥4.5 |
| accent `#C2410C` on surface-high `#F5EFE9` | 4.54:1 | ≥4.5 |
| accent `#C2410C` on accent-soft-bg `#FFF3E8` | 4.74:1 | ≥4.5 |
| white on accent `#C2410C` (badge/day) | 5.18:1 | ≥4.5 |
| `#141414` on accent-fill `#FF7A00` (button) | 7.05:1 | ≥4.5 |
| `#000000` on accent-fill `#FF7A00` | 8.04:1 | ≥4.5 |
| accent-fill `#FF7A00` on brand-ink `#141414` | 7.05:1 | ≥4.5 |
| success `#1B7F3B` on `#F4F5F7` / `#FFFFFF` | 4.64 / 5.07:1 | ≥4.5 |
| white on primary `#1C1C1E` | 17.01:1 | ≥4.5 |
| Lockdown button `#5C5C5C` vs bg `#000000` | 3.14:1 | ≥3 (component) |
| white label on Lockdown button `#5C5C5C` | 6.69:1 | ≥4.5 |
| lockdown-text-secondary `#A1A1A6` on `#000000` | 8.16:1 | ≥4.5 |

Replaced (fail): white on `#FF7A00` = 2.61:1; `#FF7A00` text on `#FAF7F3` = 2.45:1; `#8E8E93` on `#F4F5F7` = 2.99:1; `#FF5722` text on white = 3.16:1; `#333333` button on black = 1.66:1.

## Typography

Using Inter as the universal type family guarantees crisp, utilitarian legibility across all form factors. Headlines demand attention with heavy weights and tight line heights, while body text remains neutral, unobtrusive, and exceptionally readable at small sizes. Ensure that all data-heavy displays (such as timers and coin balances) utilize tabular lining figures to prevent layout jitter.

## Layout & Spacing

A fluid grid system governs the interface, adapting dynamically to mobile and desktop viewports while preserving generous exterior margins (`1.5rem`) to frame the content. 

- **Layout Model:** 12-column fluid grid with `1rem` gutters.
- **Rhythm:** Rooted in an 8px base scale, ensuring predictable vertical rhythm between stacked cards, list items, and hero elements.
- **Breakpoints:** Mobile (< 768px) utilizes single-column stacked cards with edge-to-edge padding; Tablet and Desktop expand into multi-column masonry and dashboard grids.

## Elevation & Depth

Depth is achieved primarily through soft, diffuse drop shadows that create a floating 3D effect without visual clutter. 

- **Card Elevation:** Standardized with `box-shadow: 0 20px 40px rgba(0,0,0,0.08)` to make pure white cards pop against the `#F4F5F7` background.
- **Interactive States:** Elevated elements scale up slightly on active press (not in Lockdown).
- **Dark Contexts:** Lockdown is a **static** pure black (`#000000`) screen: no animation, no glow, no pulsing, no motion effects (the countdown digits update once per second only). Elevation uses borders ≥3:1 (`#5C5C5C`). The "Hold to Leave" button is `#5C5C5C` (3.14:1 vs black) with white label (6.69:1). A small indicator "Phiên đang được ghi" is shown.

## Shapes

The shape language combines strict pill-shaped geometry with generous, friendly card radii to balance utilitarian precision with consumer approachability.

- **Buttons & Badges:** Fully pill-shaped (`border-radius: 999px`) for primary actions, navigation bars, and category toggles.
- **Cards & Containers:** Large-scale rounding (`border-radius: 24px`) for primary content cards, modals, and receipt summaries, reinforcing the modern app aesthetic.

## Components

### Buttons
- **Primary:** Matte black (`#1C1C1E`) fill with white text, pill-shaped (`999px`), featuring generous vertical padding for thumb-friendly touch targets.
- **Secondary / Toggle:** White background (`#FFFFFF`) with dark text, transitioning to matte black when active.
- **Accent:** Brand orange `#FF7A00` fill with black `#141414` label for accent buttons; deep orange `#C2410C` for Coins text/icons. Never red.

### Chips & Badges
- Pill-shaped small containers used for coin balances and category tags. Coin badges use `#FFF3E8` background with `#C2410C` text to draw immediate visual interest.

### Input Fields & Controls
- Clean, borderless or soft-bordered input fields embedded within white container cards. Segmented controls use pill-toggle styling to switch between session durations (e.g., 25m vs 50m).

### Checkboxes & Radios
- Utilitarian, high-contrast indicators utilizing success green (`#1B7F3B`) for selected states and neutral grays for unselected defaults.

### Cards
- Pure white (`#FFFFFF`) surfaces with `24px` corner radii and the system-standard diffuse shadow (`0 20px 40px rgba(0,0,0,0.08)`). Used universally for dashboard modules, session summaries, and shop items.

### Lists & Navigation
- **Bottom Navigation:** Floating pill-shaped matte black bar housing minimalist white iconography.
- **Lists:** Clean vertical stacks with generous item padding, supporting avatar graphics, primary title text, secondary metadata (`#6C6C70`), and inline warning badges (`#BA1A1A`) only for errors/exit alerts.
- **Single navigation:** one bottom navigation bar per screen.