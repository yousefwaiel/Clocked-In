# Clocked In

A debt-payoff clicker. Click **Work** to earn wages, let part of every paycheck pay down your debt, buy upgrades with the rest, and quit for a better job once you're debt-free. Go from Janitor to a debt-free CEO without letting interest bankrupt you.

Design: [docs/gdd.md](docs/gdd.md)

## Requirements

- [Odin](https://odin-lang.org/docs/install/) compiler (built and tested with `dev-2026-09-nightly`)
- Raylib comes bundled with Odin as `vendor:raylib`, so there's nothing else to install

## Build and run

From the repository root:

```bash
odin run src -out:build/clocked_in
```

Or build once and run the binary:

```bash
mkdir -p build && odin build src -out:build/clocked_in && ./build/clocked_in
```

On Windows, use `-out:build/clocked_in.exe`.

Run the logic tests (no window opens):

```bash
odin test src -out:build/tests
```

## Controls

| Input | Action |
|---|---|
| Click **WORK** / Space | Earn money |
| Click an upgrade / keys 1-5 | Buy that upgrade |
| Click **QUIT JOB** / Q | Quit for the next job (only at zero debt) |
| Esc / P | Pause |
| Enter / click | Confirm on title and end screens |

The title screen explains the rules, so you don't need this README to play.

## Code layout

```
src/
  main.odin       game loop: input -> update -> draw
  game.odin       Game struct, game states, all update logic
  entities.odin   Entity data (work button, coworkers, popups) and their update
  economy.odin    jobs, upgrades, tuning values and derived formulas
  input.odin      raw keys/mouse -> Actions
  layout.odin     screen rectangles shared by input and render
  render.odin     drawing only; takes the Game by value and never changes it
  game_test.odin  logic tests driven through game_update
```

**Game states:** Title → Playing ⇄ Paused; Playing → Job_Complete → Playing (next job); Playing → Game_Over / Victory → Title.
