# 🐔 LENAL — Stylized Indian Comic Adventure

A complete, stylized 3D indie adventure game set in a vibrant Indian village, built with **Godot 4**.

> *"A tiny adventure. A missing chicken. One strange cave."*

---

## 🏆 Project Info & Credits

- **Game**: LENAL
- **Event**: Developed for **TGC Game Jam 2026**
- **Team**: **Winter Soldiers**
- **Engine**: Godot Engine 4 (GL Compatibility renderer for browser & desktop)
- **Visuals**: Stylized Indian comic aesthetic with warm cinematic daytime lighting
- **Character Rig & Animations**: 
  - [Universal Animation Library (Standard)](https://quaternius.itch.io/universal-animation-library)
  - Creator: **Quaternius** (CC0 1.0 Universal Public Domain)
- **Audio & Music**: Self-contained procedural synthesis engine (`res://scripts/sfx.gd`), zero external audio dependencies (CC0 1.0)

---

## 🎮 The Complete Game Flow

```
MAIN MENU (Title, Start, Settings, Credits, Exit)
  ↓
INDIAN VILLAGE
(Houses with tiled roofs, tea stall with banner & awning, scooter,
 water tank tower, banyan tree & chabutra, temple gopuram, clay matkas, charpai)
  ↓
TALK TO OLD MAN (Comic speech bubble UI, character movement locked)
"Beta, I need your help... My chicken is missing. She stole my lantern."
  ↓
FOLLOW / CHASE THE CHICKEN (Animated waddling run across the village)
  ↓
CATCH CHICKEN & RETRIEVE LANTERN: "YOU GOT THE LANTERN."
  ↓
RETURN TO OLD MAN
"Ah. You found it... Forget that. Go to the cave. You'll understand."
  ↓
EXPLORE THE CAVE (Ambient cave music cross-fade, glowing crystal chamber)
  ↓
FIND CAVE NOTE: "YOUR WORK IS TO GO BACK TO THE OLD MAN."
  ↓
RETURN TO VILLAGE: Old Man has mysteriously vanished!
  ↓
ENDING TABLE (Dramatic camera zoom + 1-second suspense pause)
  ↓
COMIC REVEAL: "TAKE YOUR MONEY NOOB!"
  ↓
VICTORY CARD (★ LENAL: QUEST COMPLETE ★ | REWARD: ₹500 ($5) | PLAY AGAIN / MAIN MENU)
```

---

## 🕹️ Controls

| Key / Input | Action |
| :--- | :--- |
| **W, A, S, D** | Move Character (Smooth acceleration & deceleration) |
| **Shift (Hold)** | Run / Sprint |
| **Space** | Jump (with Jump Start, Fall & Land animations) |
| **Mouse** | Orbit Camera (Smooth 3rd-person SpringArm3D with building collision) |
| **E / Space / Left Click** | Interact / Advance Comic Dialogue |
| **Esc** | Pause Menu (Resume, Restart, Settings, Main Menu) |

---

## ⚙️ Features

1. **Third-Person Movement & Camera**:
   - `CharacterBody3D` with smooth acceleration, deceleration, and direction rotation.
   - Rigged 3D humanoid using Quaternius Universal Animation Library (`UAL1_Standard.glb`).
   - `SpringArm3D` camera with ray-casting wall collision prevention.
2. **Comic Dialogue UI**:
   - Off-white cream card with rounded 3px dark borders and drop shadows.
   - Gold speaker badge ("OLD MAN" / "PLAYER").
   - Slide/fade entrance tween and player movement lock during conversation.
3. **Audio & Dynamic Music**:
   - Procedural runtime synthesis for footsteps, jumps, landings, chicken clucks, lantern pickup, UI clicks, and dramatic stings.
   - Distinct procedural ambient music loops for Main Menu, Village, and Cave.
   - Master, Music, SFX volume buses and mouse sensitivity sliders in Settings.
4. **Complete Restart System**:
   - Pause menu (ESC) with instant clean reset of player, quest states, NPC, cave, and UI.

---

## 🚀 Running the Game

Run the project directly:

```powershell
.\play.bat
```

Or run via Godot CLI:

```powershell
godot
```

Or run automated feature verification:

```powershell
godot --headless --script tests/test_full_game_loop.gd
godot --headless --script tests/test_full_game_features.gd
godot --headless --script tests/test_ual1_integration.gd
```

