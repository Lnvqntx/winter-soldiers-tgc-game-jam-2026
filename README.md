# 🐔 LENAL

A comedic 3D Indian village adventure built with **Godot 4**.

> **"One small Indian village → one NPC → one chicken → one short chase → one cave → one ridiculous twist."**

---

## 🎮 The Gameplay Loop

```
START
  ↓
Indian Village (Houses, tea stall, tree chabutra, charpai, matkas, crates)
  ↓
Talk to Old Man: "Beta, I need your help... My chicken stole my lantern."
  ↓
Follow / Chase the Chicken (scripted waddling run across the village)
  ↓
Catch Chicken & Take Lantern: "YOU GOT THE LANTERN."
  ↓
Return to Old Man: "Forget that... Go to the cave. You'll understand."
  ↓
Walk into Tiny Cave (dark rocky tunnel leading into a glowing crystal chamber)
  ↓
Find Note: "YOUR WORK IS TO GO BACK TO THE OLD MAN."
  ↓
Return to Village: Old Man has disappeared!
  ↓
Table with $5 & Note: 1-second dramatic suspense pause + camera zoom
  ↓
"TAKE YOUR MONEY NOOB!" (Comedic brass fanfare)
  ↓
★ QUEST COMPLETE ★ (Reward: $5 — THANKS FOR PLAYING)
```

---

## 🕹️ Controls

| Key | Action |
| :--- | :--- |
| **W, A, S, D** | Move |
| **Mouse** | Camera Look |
| **Space** | Jump |
| **E** | Interact |
| **Esc** | Toggle Mouse Capture |

---

## 🛠️ Tech Stack

- **Engine**: Godot 4.3+ (GL Compatibility renderer)
- **Language**: GDScript
- **Audio**: Procedurally synthesized retro SFX (`AudioStreamWAV` generated at runtime: footsteps, chicken clucks, lantern chime, cave drone, dramatic sting, comedic fanfare)
- **Art**: Stylized 3D primitives

---

## 🚀 Running the Game

Open this project in Godot 4 or run from the command line:

```powershell
godot
```

Or run automated integration tests:

```powershell
godot --headless --script tests/test_full_game_loop.gd
```
