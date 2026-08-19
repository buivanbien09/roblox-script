# 28th6 Roblox Hub
*Author: Bien*

Welcome to the **28th6 Hub** - A multi-functional Roblox Script, heavily optimized to bypass Anti-Cheats and provide a buttery-smooth experience on both PC and Mobile devices.

The script interface is built on the [Fluent](https://github.com/dawid-scripts/Fluent) framework, featuring a sleek, modern Dark Mode UI.

---

## 🌟 Key Features

### 🏃‍♂️ Player Tab
- **Speed Boost:** Accelerate your walk speed (bypasses default speed limits).
- **NoClip (Physics Bypass):** Walk through walls without getting stuck.
- **Fly (Stealth Fly):** Zero-gravity stealth flying mode that avoids physics glitches and Anti-Cheat detections.
- **Float:** Hover mid-air in place.
- **Spinbot:** Continuously spin to dodge bullets (includes a spin speed slider).

### 👁️ ESP Tab
- Visual indicators including: **Boxes**, **Names**, **Distance**, **Health**, **Tracers**, and **Chams**.
- Customizable enemy colors and maximum render distance.

### ⚔️ Combat Tab
- **Aimbot:** 
  - Mouse/Camera locking with adjustable **Smoothness**.
  - **Headshot Chance (%)** slider (Automatically randomizes aiming at the Head or the Torso to look like a legitimate player).
  - Visible Only check.
  - On-screen FOV Circle and Target Info overlay.
- **Kill Aura:**
  - Massive destruction radius up to **1000 Studs**.
  - God-speed attack delay (Minimum **0.001s**).
  - Smart **Headshot Chance (%)** mechanism.
  - 8 different Remote methods built-in to support dozens of different games.
  - **Auto Check:** Strictly ignores dead bodies, deleted characters, and newly spawned players with ForceFields (Spawn Protection) to prevent false flags and bugged attacks.
- **Weapon Mods:** 
  - No Spread / No Recoil.
  - Infinite Ammo.
  - Fast Fire (Removes shooting delay).

### 🚀 Teleport Tab
- Teleport to specific players.
- **Click / Tap Teleport:** Click (on PC) or Tap (on Mobile) anywhere on your screen to instantly teleport there.
- Two movement modes: **Instant** (Snap to location) and **Tween** (Glides through walls using stealth physics without getting bounced back).

### 🛠️ Misc Tab
- Rejoin Server / Server Hop (Automatically finds and transfers you to an underpopulated server).
- **Anti AFK:** Simulates input and aggressively disables native Roblox idle kick connections. Leave your game running 24/7 without disconnecting.
- **Force Time of Day:** Locks the in-game time. Uses a Multi-layered Interceptor (`RenderStepped` + `Heartbeat` + `Property Signal`) making it completely unbreakable by any server-sided Admin scripts.
- **Troll Tools (Bang / Jerk Off):** Custom troll animations that perfectly support both R6 and R15 rigs.

---

## 📱 Compatibility
This script is fully optimized for **PC Executors** and provides top-tier support for the **Mobile Ecosystem (Delta, Codex, Arceus X, etc.)**:
- The Click Teleport feature integrates touchscreen Raycasting specifically for Tap-to-Teleport functionality.
- Render loops (`RenderStepped`, `Heartbeat`) are highly optimized to minimize RAM usage and prevent frame drops on mobile devices.

## 💡 Notes
- Only enable features as you need them to prevent unnecessary lag on lower-end devices.
- Some Kill Aura methods are game-specific. If your aura isn't doing damage, try switching the Method in the dropdown menu.
