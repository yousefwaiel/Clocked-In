# Attribution

Inspired by Cookie Clicker.

## AI Use

- **ChatGPT:** rephrased and proofread the first GDD draft (CP1).
- **Claude Code:** restructured and extended the GDD for CP2 (design pillars, goal/opposition/decisions/rules, ranked scope with cut line, lose condition, Debt Collector plan). Helped to write the CP2 code in `src/` (game loop, game states, entity collection, input-to-actions, economy, rendering) and the logic tests in `src/game_test.odin`. For CP3, helped move the tuning, job and upgrade values into `data/*.json` with a loader (`src/data.odin`), and add sound loading/playback (`src/assets.odin`). Also used to find CC0 sound effects.

## Assets

All visuals are Raylib shapes drawn in code. Text uses Raylib's built-in default font (part of Raylib, zlib/libpng licence).

### Sounds

All sound effects are by Kenney (www.kenney.nl), licensed **CC0 1.0** (public domain): https://creativecommons.org/publicdomain/zero/1.0/

| File | Used for | Pack |
|---|---|---|
| `assets/sounds/click_001.ogg` | Work click | [Interface Sounds](https://kenney.nl/assets/interface-sounds) |
| `assets/sounds/error_004.ogg` | Can't buy upgrade | [Interface Sounds](https://kenney.nl/assets/interface-sounds) |
| `assets/sounds/confirmation_002.ogg` | Quit job / retire | [Interface Sounds](https://kenney.nl/assets/interface-sounds) |
| `assets/sounds/error_006.ogg` | Bankrupt | [Interface Sounds](https://kenney.nl/assets/interface-sounds) |
| `assets/sounds/handleCoins2.ogg` | Buy upgrade | [RPG Audio](https://kenney.nl/assets/rpg-audio) |
| `assets/sounds/handleCoins.ogg` | Take Payday Loan | [RPG Audio](https://kenney.nl/assets/rpg-audio) |
