# 28th6 Hub 🚀

A highly advanced and fully optimized Universal Roblox script built on the beautiful [LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib) UI framework. This script is designed to be lightweight, lag-free, and compatible with a wide variety of games. It features powerful combat mechanics, deep visual enhancements, and movement exploits.

---

## 🌟 Key Features

### ⚔️ Combat
- **Aimbot / Silent Aim**: Highly precise aiming with FOV circle, hit chance calculation, distance checks, and wall checks.
- **Universal Kill Aura**: Automatically attacks targets within a specified radius. Includes **4 distinct network bypass methods** to work on various game architectures:
  - `WeaponHit` (Game 1)
  - `RequestActionSync` (Game 2)
  - `GunRemote` (Game 3)
  - `WeaponsSystem` (Game 4)
- **Hitbox Expander**: Enlarges enemy hitboxes (Head, Torso, or Root) and makes them partially transparent, allowing you to hit targets effortlessly without precise aiming.

### 👁️ Visuals (ESP)
- Fully customizable ESP with dynamic, perfectly aligned bounding boxes.
- **Skeletons (Bones)**, Tracers, Player Names, Health Bars, Distance, and current Weapon display.
- Advanced settings: Custom colors, Team Check, and Wall Check (Visibility).

### 🏃 Movement
- **Speed & Flight**: WalkSpeed multipliers, Infinite Jump, Noclip, and Fly (with Float/Lock-Y options).
- **Auto-Climb & Auto-Walk**: Automatically climb up walls and automatically walk forward independently of other keypresses.
- **Vehicle Fly**: Take control of vehicles and fly them through the sky.
- **Misc Movement**: Spin Player (Spinbot), Freeze Position, and Anti-Wind (ignore map wind physics).

### 🛠️ Misc & Utility
- **Instant Interact**: Bypass long wait times on Proximity Prompts (press E instantly).
- **Auto Pickup**: Automatically grabs nearby dropped tools/items and teleports them to your inventory.
- **Anti-AFK**: Silently prevents Roblox from kicking you after 20 minutes of inactivity.
- **Integrated Debugger**: Built-in tab to instantly load **SimpleSpy V3** for intercepting and analyzing RemoteEvents/RemoteFunctions.

### ⚙️ Settings & Customization
- **ThemeManager**: Customize UI colors and save your favorite aesthetics.
- **SaveManager**: Automatically saves your toggle/slider configurations and auto-loads them the next time you inject.
- **Dynamic Tooltips**: Every single toggle and slider features descriptive tooltips for a seamless user experience.

---

## 🚀 Getting Started

1. Open `Script.lua` and copy the entire source code.
2. Launch your preferred Roblox executor.
3. Attach/Inject your executor into Roblox.
4. Paste the script and Execute!
5. Use the Right `Shift` key to toggle the menu interface on and off.

## 📝 Technical Notes
- **Optimization**: This script has been aggressively optimized. Over 2,300 lines of hardcoded debugger bloat were removed and replaced with a dynamic cloud-loader, dropping the file size from ~240KB to ~140KB for instant execution.
- **Kill Aura Compatibility**: Because every Roblox game is coded differently, you may need to cycle through the 4 Kill Aura methods in the Combat tab to find the one that successfully registers damage in your specific game.
