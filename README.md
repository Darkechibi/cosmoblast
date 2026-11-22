# CosmoBlast

**Atari 2600 homebrew · based on Space Zap · intentionally 4K**

CosmoBlast is a homebrew Atari 2600 take on the original arcade game **[Space Zap](https://en.wikipedia.org/wiki/Space_Zap)** (Game-A-Tron / Midway, 1980): fixed base, invaders from four sides, aim and fire — you never move the base.

Think of it as the 2600 cartridge that **might have existed** in another timeline — the kind of early, no-frills port a publisher could have shipped when carts were still a hard **4K**. Same arcade idea, squeezed into what a late-’70s / early-’80s VCS game actually had to live with.

This project was built under that rule for real: **stay inside a classic 4K cartridge.** Not 8K with bankswitching. Not Superchip RAM. A single 4096-byte ROM.

**Current release: v0.99** · playable ROM: [`release/CosmoBlast_v1.3.a26`](release/CosmoBlast_v1.3.a26)

---

## Why 4K matters

The Atari 2600 has almost no hardware help. Two player sprites, two missiles, one ball, a playfield, and 128 bytes of RAM. A 4K cartridge is the classic ceiling for a whole game: title, play, sound, scoring, death, and game over — all in one bank.

CosmoBlast treats that limit as a design choice, not an inconvenience:

| Constraint | What we did |
|---|---|
| **4096 bytes of ROM** | Every feature had to earn its bytes. Features were cut, shared, or rewritten so the game still fits. |
| **No bankswitching** | One contiguous program. No “extra room” behind a bank switch. |
| **No Superchip** | Stock console RAM only. Variables were reused across modes (play vs breakup). |
| **Standard kernel** | batari Basic’s 2-line kernel with `pfheights` — no custom kernel rewrite. |

When something cool would not fit, we did not “just go to 8K.” We redesigned: one shared missile for satellites, flicker for multiple orbiters, a score digit for hits left instead of a second display, and so on. The unfinished bytes of free space at the end of the ROM are part of the story — often under 50 bytes by the end of a feature pass.

That is the point of this homebrew: **prove the game can feel finished inside the original cartridge size.**

---

## The game

Your base sits in the center of the screen. Mines (invaders) spawn from the top, bottom, left, or right and fly straight at you. Push a direction to fire a short laser burst that way. Survive as long as you can.

- **4 game numbers** (easy → expert): faster enemies, faster speed-up, higher scoring
- **Satellites** after every 8th kill: usually one, sometimes two, rarely three
- Satellites orbit, then dive if you leave them alone
- Hits left + score on the bottom digits; extra hit every 1,000 points
- Cracking breakup when the last hit is gone, then **GAME OVER**

Full player instructions live in [`release/CosmoBlast_Manual.md`](release/CosmoBlast_Manual.md).

---

## Play it

1. Install [Stella](https://stella-emu.github.io/) (or RetroArch with a Stella core).
2. Open `release/CosmoBlast_v1.3.a26` (or `bin/cosmoblast.bin` after a local build).

| Input | Action |
|---|---|
| Joystick directions | Fire a 3-pulse burst that way |
| Red button | Start from the title screen (does not fire in play) |
| Left / Right on title | Choose game 1–4 |
| GAME RESET | Soft reboot to the title |
| Color / B&W switch | Pause (B&W) / resume (Color) — Stella: F4 / F3 |

**Analog pads:** the stick must settle on one direction before a new aim registers, so diagonals and drift are less likely to fire the wrong way. Raise the emulator deadzone if a stick still drifts.

**RetroArch tip:** set Port 1 device type to **Joystick** (not Automatic). CosmoBlast is not in Stella’s ROM database, so Automatic can pick the wrong controller type.

---

## Build

```powershell
.\build.ps1
```

Requires:

- Windows PowerShell
- [wasmtime](https://wasmtime.dev/) (for the included batari Basic 1.9 WASM toolchain)
- The bundled kit under `tools/bB`

Successful builds write a **exactly 4096-byte** `bin/cosmoblast.bin`. The build script fails if the ROM is any other size — that check exists so a broken assemble cannot be mistaken for a shippable 4K cart.

Source of truth for the game: `src/cosmoblast.bas`.

---

## Project layout

```
src/cosmoblast.bas          Game source (batari Basic)
bin/cosmoblast.bin          Latest local build (4K)
release/                    Shipped .a26 ROMs, tagged sources, manual
tools/                      Stella helpers (snap, soak, bot) + bB 1.9
build.ps1                   Compile + size-check
```

Historical release ROMs (v1.0 → v1.3) are kept under `release/` so you can compare how the 4K budget was spent as features landed.

---

## The original arcade game

CosmoBlast is based on ***Space Zap***, the four-way fixed-base arcade shooter originally made by **Game-A-Tron** and released / published by **Midway** in **1980**. You sit in a stationary base; enemies come from the four screen edges; you aim and fire. That core idea is what this 2600 homebrew is chasing — as the cart that mighta coulda existed in a different timeline.

## Theme music (pre-AI)

Long before this homebrew existed as a finished ROM, [**Cosmo Blast** by FoxSynergy (A Digitized Orange)](https://opengameart.org/content/cosmo-blast) was composed as arcade-style space music for a Cosmo Blast–style game if one ever got made. It was posted on OpenGameArt in **2012** — human-made, pre-AI — and is licensed **CC-BY 3.0**. Credit FoxSynergy / A Digitized Orange if you use it alongside the game.

## Credits & inspiration

- **Design / art direction:** LightChibi
- **Code:** CosmoBlast homebrew (this repo)
- **Arcade original:** *Space Zap* — Game-A-Tron / Midway, 1980
- **Theme music:** [FoxSynergy — Cosmo Blast](https://opengameart.org/content/cosmo-blast) (CC-BY 3.0, 2012)
- **Framing:** unofficial “what if” 2600 version of that arcade game
- **Toolchain:** [batari Basic](https://github.com/batari-Basic/batari-Basic) 1.9 + DASM

CosmoBlast is an unofficial homebrew fan work. It is not affiliated with Midway, Atari, Game-A-Tron, or the Space Zap rights holders.

---

## License

Source and ROM in this repository are provided for personal and educational use. If you redistribute, keep credit and the 4K “no bankswitch” spirit of the project intact.
