# GridWars (LÖVE Edition)

A high-intensity twin-stick arcade shooter inspired by *Geometry Wars*, built using Lua and the [LÖVE (Love2D)](https://love2d.org/) framework.

This project features a physics-based reactive grid, neon aesthetics, particle systems, and chaotic gameplay.

## 🎮 Features

*   **Reactive Grid:** A physics-based background that warps and ripples based on explosions and player movement.
*   **Neon Aesthetics:** Additive blending for that classic glowing arcade look.
*   **Enemy Variety:**
    *   🔴 **Seeker:** Chases you relentlessly.
    *   🟢 **Pinwheel:** Moves in a chaotic sine-wave pattern.
    *   🟡 **Dasher:** Aims carefully, then launches a high-speed attack.
*   **Power-ups:**
    *   **Spread Shot (Cyan):** Fires a shotgun-style blast.
    *   **Rapid Fire (Orange):** Machine-gun speed.
*   **Combat Mechanics:**
    *   **Combo System:** Chain kills to increase your score multiplier.
    *   **Panic Bombs:** Clear the screen when overwhelmed.
    *   **Screen Shake:** Juicy feedback on impact.

## 🕹️ Controls

| Key / Input | Action |
| :--- | :--- |
| **W, A, S, D** | Move Ship |
| **Mouse** | Aim |
| **Left Click** | Fire Weapon |
| **Spacebar** | **BOMB** (Clear Screen) |
| **R** | Restart Game (when Game Over) |

## 🚀 How to Run

You need the **LÖVE** framework installed to run this game.

### Linux (Fedora)
```bash
sudo dnf install love
cd GridWars
love .