# DropIt! — AI UI Generation Prompt (Detailed Colors & Styles)

*Lưu ý: Copy toàn bộ phần tiếng Anh dưới đây để đưa vào các công cụ AI (Stick UI, v0.dev, Midjourney, Galileo AI).*

## 🎨 Global Design System & CSS Variables

**Theme & Vibe:** Premium, Apple-like smoothness, highly interactive, clean. Inspired by modern food delivery apps (white cards on light backgrounds with stark black buttons).
**Shapes:** Pill-shaped buttons (`border-radius: 999px`), rounded cards (`border-radius: 24px`).
**Typography:** Modern Sans-serif (Inter, SF Pro Display, or Poppins). Bold, large headings; clean, readable body text.
**Shadows:** Soft, diffuse drop shadows for a 3D floating effect (`box-shadow: 0 20px 40px rgba(0,0,0,0.08)`).

**Exact Color Palette:**
*   **App Background:** Very Light Gray / Off-White (`#F4F5F7`) - Allows white cards to pop.
*   **Card Background:** Pure White (`#FFFFFF`).
*   **Primary Actions / Bottom Nav:** Matte Black (`#1C1C1E`) - Stark contrast, modern feel.
*   **Accent Color (Coins, text/icons):** Burnt Orange (`#B02F00`, 6.46:1 on white). `#FF5722` only for large decorative fills, never text. Never use red as accent.
*   **Warning/Error (only errors and exit alerts):** `#BA1A1A`.
*   **Success Color:** Green `#1B7F3B` for text (`#34C759` decorative only).
*   **Text Colors:** Primary Text (`#111111`), Secondary Text (`#6C6C70`, 4.79:1 on `#F4F5F7`).
*   **Source of truth:** `dropit/DESIGN.md`. Use terms: "Coins", "group" (nhóm), "group owner" (chủ nhóm). No points/XP/levels/ranks/leaderboards.

---

## 📱 Detailed Screen Prompts (Copy each to your AI tool)

### 1. Onboarding / Splash Screen
**Prompt:**
> Generate a modern onboarding screen for a premium productivity app.
> **Colors:** Background is clean `#F4F5F7`.
> **Visual:** In the center, a highly detailed 3D illustration of a coffee cup, a Pomodoro timer, and floating orange coins (`#B02F00`) landing on a clean white desk.
> **Typography:** Bold headline (`#111111`): "Focus Together, Achieve More". Subtitle (`#6C6C70`).
> **UI Elements:** At the absolute bottom, a massive, full-width, pill-shaped primary button in Matte Black (`#1C1C1E`) with white text saying "Get Started".

### 2. Member Home Screen (Dashboard)
**Prompt:**
> Generate a home screen dashboard for an office productivity app.
> **Colors:** Background is light gray (`#F4F5F7`).
> **Header:** User profile avatar on the left. On the right, a pill-shaped badge showing Coin balance (`#B02F00` text on `#FFF1EC`). Greeting text "Next session of your group" in dark text.
> **Main Content:** One large white card (`#FFFFFF`, soft shadow) showing only the next scheduled session of the user's own group (set by the group owner): title, time, duration (25 or 50 min), Coin reward (25 min = 10, 50 min = 25). No live rooms, no room search, no solo sessions.
> **Bottom Nav:** A floating, pill-shaped Matte Black (`#1C1C1E`) bottom navigation bar containing 4 white minimalist icons.

### 3. Session Lobby (Before Lockdown - like Pizza detail screen)
**Prompt:**
> Generate a product detail-style screen for joining a focus session.
> **Layout:** Hero image at the top showing a beautiful 3D focus icon (clock or brain).
> **Colors:** Clean white background (`#FFFFFF`).
> **UI Elements:** Read-only session info (duration fixed by the group owner's schedule), list of group members joining (max 10), and the warning: "Leaving the app will notify your whole group by name and the whole session loses its Coins." No stakes, no fees.
> **Bottom Area:** A massive Matte Black (`#1C1C1E`) pill-shaped button saying "Join Session".

### 4. Lockdown Mode (Active Focus Session)
**Prompt:**
> Generate a pitch-black, dark-mode full-screen UI for an active focus session.
> **Colors:** Absolute black background (`#000000`) for OLED battery saving.
> **UI Elements:** In the dead center, a static, minimalist circular progress ring in White (`#FFFFFF`). Inside the ring, large typography showing "24:59". Small label "Session is being recorded" in `#A1A1A6`. The screen is fully static: no animation, glow, pulse or motion effects.
> **Action:** Bottom center features a dark gray (`#5C5C5C`, 3.14:1 vs black) pill-shaped button with white label "Hold to Leave". No sensors, no phone-flip instructions.

### 5. Success & Checkout/Reward Screen
**Prompt:**
> Generate a celebratory success screen similar to a modern payment success UI.
> **Colors:** Background is light gray (`#F4F5F7`).
> **Visual:** A round Green Checkmark (`#1B7F3B`) in the center.
> **Typography:** "Session Successful!" in large bold dark text (`#1C1C1E`).
> **Card:** A white "receipt" or "order summary" card (`#FFFFFF`) with soft shadows detailing: Coins earned for this session (25 min = 10, 50 min = 25, max 100/day). No streak bonus, no ranking, no score.
> **Action:** A Matte Black (`#1C1C1E`) pill-shaped button saying "Back to Dashboard".

### 6. Group Owner Monthly Report
**Prompt:**
> Generate a clean monthly report screen for a group owner (chủ nhóm). Show the report purpose at the top. Rows sorted by name A→Z. No streaks, no Coins, no ranking.
> **Colors:** Off-white background (`#F4F5F7`).
> **Cards:** Data is displayed in pure white (`#FFFFFF`) cards with soft 20px rounded corners.
> **Charts:** Include a clean, minimalist bar chart using Matte Black (`#1C1C1E`) and Burnt Orange (`#B02F00`) bars to show focus trends.
> **List:** A list of team members with their avatars. If a member left the app during a session, show a Red (`#BA1A1A`) warning badge next to their name. Overall aesthetic is professional, clean, and data-driven like Notion.

### 7. Shop & Profile Screen
**Prompt:**
> Generate a masonry grid Shop interface for buying digital profile items.
> **Colors:** Light background (`#F4F5F7`).
> **Grid:** 2-column grid of pure white (`#FFFFFF`) cards.
> **Cards:** Each card displays a cosmetic item only: avatar frame, background, or title. Below the item, the price in Coins (`#B02F00`). Labels: Owned / Equipped / Need N more Coins. No boosters, no Double Coin, no Mystery Box/random rewards, no "+% Coins" items, no gifting.
> **Action:** Each card has a small Matte Black (`#1C1C1E`) "Buy" button; owned items show "Equip" / "Unequip".