# CP5 Balancing - Bot Playtest Data

> **AI disclosure:** Claude Code wrote the bot code and ran the tuning passes, and drafted the analysis in this doc from the bot data. The text was then rephrased to match my own wording, and grammar mistakes were fixed with AI. The data and numbers come straight from the CSVs in `playtests/`.

Raw data: `playtests/sim_baseline.csv` → `sim_guard.csv` → `sim_tuned.csv`. Re-run any time with `./build/clocked_in --sim <label>`.

## Method

- 16 bots play a full career headlessly at 60 updates/sec, using the real `game_update` (same code path as the game).
- 4 click speeds: 4, 5, 6, 7 clicks/sec. 4 strategies:
  - **Saver:** never takes a loan.
  - **Careful:** takes a loan only if debt stays under the collector's approach line (115%).
  - **Bold:** takes a loan while debt stays under 150%.
  - **Reckless:** takes every loan offered.
- Every bot checks the shop twice a second. Priority: Refinance → Budget App → the cheaper of Coworker or Overtime. Bots quit as soon as debt hits 0.
- Logged per job: time, outcome, loans taken, Debt Collector visits, cash taken by him, and peak debt ratio.

**What I was aiming for (from the GDD):** a full run should take around 10 minutes, taking a loan should actually be a choice (faster but riskier), and the collector should punish you for borrowing too much.

## Baseline (CP4 values)

| Strategy | 4 cps | 5 cps | 6 cps | 7 cps | Collector visits |
|---|---|---|---|---|---|
| Saver | 6m 29s | 5m 37s | 5m 01s | 4m 28s | 0 |
| Careful | 7m 47s | 6m 45s | 6m 02s | 5m 23s | 0 |
| Bold | 7m 57s | 6m 54s | 6m 10s | 5m 31s | 0 |
| Reckless | bankrupt 0m 01s | bankrupt 0m 01s | bankrupt 0m 01s | bankrupt 0m 01s | 0 |

**What was wrong:**
1. **You could lose instantly.** Taking 2 loans as a Janitor puts your debt at exactly 2x, so pressing 5 twice ends the game in about a second.
2. **Loans were never worth it.** Every bot that borrowed finished slower than the one that didn't (20-23% slower at 5 cps). So there's no real choice, you just never take loans.
3. **The collector did nothing.** None of the bots that survived ever got a visit from him.
4. **Runs were too short.** 4.5 to 6.5 minutes when I wanted about 10.

## Changes

| # | Change | Where | Fixes |
|---|---|---|---|
| 1 | A loan that would reach the bankrupt limit is blocked ("Would bankrupt you") | `purchase_status` in `src/economy.odin` | Problem 1 |
| 2 | Loan debt 40% → 20% of starting debt; loan pay ×1.5 → ×1.4 | `data/tuning.json` | Problem 2 |
| 3 | Collector adds a late fee (2% of starting debt/sec) when you have no cash | `src/collector.odin`, `collector_late_fee` | Problems 2 and 3 (keeps Reckless from winning) |
| 4 | All starting debts ×2 (Janitor $50 → $100 … CEO $1.5M → $3M) | `data/jobs.json` | Problem 4 |

**After change 1 only** (`sim_guard.csv`): the Reckless bot lasted 2 to 2.5 minutes and got to Middle Manager. But once I made loans cheaper (without the late fee yet), Reckless turned into the *fastest* way to play: 3m 49s at 5 cps, 6 collector visits, and it never went bankrupt. Four loans basically 4x your pay, the guard keeps your debt just under the limit, and the bot spends all its cash before the collector can grab any. That's why I added the late fee (change 3).

**Values tried and rejected:**
- Collector take rate 0.4 and fee 0.8: Reckless still came out on top.
- Interest 0.005: made everyone slower by about the same amount, so the ranking stayed the same.
- Loan pay x1.3: borrowing went back to being slower than saving.
- Loan pay x1.45: Bold was 20% faster than Saver, so there'd be no reason to play safe.
- Debt x1.75: around 9 minutes at 5 cps, still a bit short.

## Tuned (CP5 values)

| Strategy | 4 cps | 5 cps | 6 cps | 7 cps | Collector visits |
|---|---|---|---|---|---|
| Saver | 12m 22s | 10m 15s | 8m 52s | 7m 50s | 0 |
| Careful | 12m 43s | 10m 35s | 9m 08s | 8m 02s | 0 |
| Bold | 10m 57s | **9m 14s** | 8m 04s | 7m 10s | 0 (he walks in, but never reaches the cash) |
| Reckless | bankrupt 2m 16s (Cubicle Drone) | bankrupt 3m 02s (Middle Manager) | bankrupt 2m 44s (Middle Manager) | bankrupt 3m 43s (CEO) | 4–6 |

**Did it hit the targets?**
- **Length:** runs now take 7m 50s to 12m 22s, about 10 minutes at 5 cps. ✅
- **Loans are a real choice now:** borrowing a reasonable amount (Bold) is about 10% faster than not borrowing. Borrowing late (Careful) is a little slower than not borrowing at all, and borrowing everything gets you bankrupt. ✅
- **The collector actually matters:** he shows up 4-6 times a run for people who borrow too much, and the late fee is what ends up bankrupting them. Bold players see him start walking in as a warning, but he never gets to their cash. ✅

## Limits of this data

- Bots aren't real players. They click at the exact same speed the whole time, never misread anything on screen, and always follow the same rule. I still need real people to playtest at CP6 to check the length and whether the collector feels fair.
- Bots never pause or stop to think, so real runs will probably be longer.
- The order the bots buy upgrades in is just one sensible order, not necessarily the best one.
