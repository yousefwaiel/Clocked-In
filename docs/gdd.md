# Clocked In - Game Design Document

**Student Name:** Yousef Waiel Said  
**Student ID:** 100857349  
**First draft:** 22/09/2026 (CP1) · **Last updated:** 17/11/2026 (CP5; scope locked at CP2)  
**Class:** CSCI 4160U Game Development  
**Repository Link:** https://github.com/yousefwaiel/Clocked-In

## Description

**Clocked In** is a debt-payoff clicker game. Every job starts with a large debt. You click **Work** to earn wages, and part of every paycheck automatically pays down that debt. You can spend what's left on upgrades that raise your income or help you pay the debt off faster.

There is one exception: **Payday Loans**. They give a big, immediate boost to your pay, but they add to your debt. And debt grows with **interest**, so if you overextend yourself, your debt can outgrow you and you go **bankrupt**.

Once your debt hits zero, you can **Quit** and move on to a better-paying job. Quitting resets your cash, debt and upgrades, but you keep a permanent **Experience multiplier** that makes every future job faster. Make it from Janitor to a debt-free CEO to win.

## Design Pillars

1. **Every paycheck has two owners.** Income is always split between you and the debt. You never get to keep all of it while you owe.
2. **Debt is both a tool and a threat.** Loans speed you up, and interest and the Debt Collector punish you for overusing them. Every loan should be a real decision.
3. **Each job is faster than the last.** Quitting has to feel like progress, never like losing your work.
4. **Readable at a glance.** Cash, debt, and how close you are to bankruptcy are always visible.
5. **Light-hearted, not punishing.** It's about paycheck-to-paycheck life, played for a smile, not for stress.

## Core Loop

**Click Work to earn wages that split between paying down your debt and buying upgrades, until the debt is gone and you quit for a better job.**

1. Click **Work** → earn money.
2. A share of every paycheck automatically goes toward debt.
3. Spend the leftover cash on upgrades.
4. Decide whether to take a Payday Loan for faster income or play it safe.
5. Keep the debt ahead of interest, or the Debt Collector walks in and starts taking your cash.
6. Pay off the debt → **Quit** → start the next, bigger job with your Experience multiplier.

## Mechanics

### Primary Mechanic (the verb)

**Work.** You click the Work button (or press Space) to earn wages.

### Secondary Mechanics

Spending cash on upgrades (5 upgrades per job, unlocked as the debt is paid down):

| Key | Upgrade | Effect | Paid with |
|---|---|---|---|
| 1 | Hire Coworker | A coworker clicks Work for you once a second (max 8) | Cash |
| 2 | Overtime | +25% pay per click | Cash |
| 3 | Budget App | +10% of every paycheck goes to debt (unlocks at 15% paid) | Cash |
| 4 | Refinance | Interest rate ×0.7 (unlocks at 30% paid) | Cash |
| 5 | Payday Loan | Pay ×1.4, adds 20% of the job's starting debt (×1.5 per loan held). Blocked if it would bankrupt you | **Debt** |

**Interest:** debt grows a small percentage every second, so stalling is never free.

**Debt Collector:** an enemy who walks into the office toward your cash as your debt grows, and takes a cut once he reaches it. See *Debt Collector (Enemy AI)* below.

### Tertiary Mechanics

**Quit / New Job (prestige):** once a job's debt is fully paid you can quit. Cash, debt and upgrades reset, and you gain a permanent **+0.5× Experience multiplier** on all pay. Each new job has a bigger debt and a higher wage.

## Debt Collector (Enemy AI)

The Debt Collector is the game's enemy. He works through systems that already exist: he reads your **debt**, walks toward your **cash** counter, and takes money out of it.

### State machine

| State | What he does | Transition |
|---|---|---|
| **Away** | Outside the office, not drawn | → Approaching when debt ≥ 115% of the job's starting debt |
| **Approaching** | Walks the path from the door toward your cash. How far along he gets depends on how much you owe | → Collecting when he reaches your cash (debt ≥ 160%); → Leaving if debt drops below 105% |
| **Collecting** | Takes 25% of your cash per second. Half pays your debt; he keeps the other half as a fee. If you have no cash, he adds a late fee to your debt (2% of starting debt per second). Cash counter turns red | → Leaving when debt drops below 105% |
| **Leaving** | Walks back to the door | → Away when he reaches the door |

The approach and leave thresholds are different on purpose (115% vs 105%), so he doesn't flicker in and out when the debt is right on the line. All thresholds, speed and take rate live in `data/tuning.json`.

### Movement: scripted

He moves along a fixed path (door → corridor → under the cash counter). His position on that path is driven by the debt: the more you owe, the closer he gets to your cash. He walks toward that point at a fixed speed instead of teleporting.

**Why scripted, not steering or pathfinding:**

- **The office is one fixed screen with nothing to route around.** A* would find the same path every time, so it would add cost without changing anything.
- **His position is the information.** Because his distance from your cash is tied to the debt, he works as a danger meter you can read at a glance (pillar 4). With steering, his position would depend on physics and timing instead of on the debt, and that signal would be lost.
- **It creates urgency.** Watching him walk closer as debt builds up pushes you to pay down debt or stop taking loans, which is the core tension of the game (pillar 2).

This approach was agreed with the TA (Nour) and approved by the professor for CP4. It replaces the seek/flee steering in the CP2 plan.

## Goal · Opposition · Decisions · Rules

- **Goal:** pay off each job's debt and climb from Janitor to a debt-free CEO.
- **Opposition:** interest that grows the debt every second, the bankruptcy limit, rising upgrade prices, and the Debt Collector.
- **Decisions:** which upgrade to buy next; whether a Payday Loan is worth its debt; whether to spend cash on upgrades or pay debt down fast enough to send the Debt Collector away; when to stop buying and just pay down debt.
- **Rules:**
  - A fixed share of every dollar earned (50% at the start) pays debt, and the rest is cash.
  - Debt grows by the interest rate every second.
  - **Lose:** debt reaches 2× the job's starting debt → **Bankrupt**.
  - **Quit** is only available at zero debt.
  - **Win:** pay off the CEO job and retire.

## MDA Framework

### Mechanics

A click-to-earn currency system, with a fixed share of income automatically going toward debt. A shop of safe upgrades and debt-funded loan upgrades. Debt goes up with loans and interest, and down with payments. A prestige system resets money and debt but grants a permanent multiplier. An enemy that drains cash unless you react to it.

### Dynamics

The main tension is deciding whether to play safely and slowly or take on more debt for faster progress. Interest punishes overextending: the more you borrow, the faster debt grows, so players should constantly be weighing how much more debt they can carry before it becomes a problem.

The prestige system creates a rubber-band effect: the first jobs feel slow, but each reset makes future jobs faster.

### Aesthetics

- **Challenge:** deciding when a loan is actually worth it, and surviving interest.
- **Fantasy:** working your way up from a minimum-wage job to the corner office.
- **Expression:** playing careful and debt-averse, or borrowing aggressively.

## Player Experience

### How should they feel? (LeBlanc's Taxonomy of Pleasures)

- **Submission (primary):** the simple, satisfying feeling of numbers going up.
- **Challenge:** the anxiety of taking on one more loan with the bankruptcy limit in sight.
- **Fantasy:** the career ladder, with job titles getting grander.

The debt system adds a small amount of anxiety that normal clicker games don't have. It should still feel light-hearted and relatable, not punishing.

## Target Player

### Bartle's Taxonomy

- **Achievers (primary):** the game is built around payoff milestones and unlocking new job titles.
- **Explorers (secondary):** players who enjoy working out the best balance of safe upgrades and loans.

## Inspirations

### Game

- **Cookie Clicker:** the click-to-earn loop and upgrade shop.
- **Universal Paperclips:** numbers as the whole world, with escalating stakes.
- **Adventure Capitalist:** prestige through resetting your business.

### Non-Game

- Debt-payoff and budgeting apps that show progress bars toward zero.
- "First to save a million" style YouTube challenge videos.
- Gig-economy and paycheck-to-paycheck culture and memes.

## Genre, Platform & Tools

- **Genre:** incremental / idle resource-management. You are grinding your way out of debt, not clicking for the sake of clicking.
- **Platform:** desktop (macOS, Windows, Linux), mouse and keyboard, 960×600 window.
- **Tools:** Odin + Raylib (`vendor:raylib`), Git/GitHub. Placeholder shapes and Raylib's default font; no custom art. CC0 sound effects from Kenney.

## Progression Over Time

| Job | Title | Starting debt | Base wage / click |
|---|---|---|---|
| 1 | Janitor | $100 | $0.25 |
| 2 | Barista | $800 | $1 |
| 3 | Intern | $6,000 | $4 |
| 4 | Cubicle Drone | $50,000 | $16 |
| 5 | Middle Manager | $400,000 | $64 |
| 6 | CEO | $3,000,000 | $256 |

- Within a job, upgrades unlock as the debt is paid down (Budget App at 15%, Refinance at 30%).
- Each job starts with more debt and pays more. The Experience multiplier (+0.5× per job) makes each new job faster than the last.
- The job titles are a small humorous reward for each quit.
- Target session: roughly **10 minutes** from Janitor to CEO. Starting debts were doubled at CP5 after bot playtests showed ~5.5-minute runs. See [balancing.md](balancing.md).

## Themes

The grind of living paycheck to paycheck and trying to work your way out of debt. It's presented with tongue-in-cheek humour rather than being serious or depressing.

## Anything Else Unusual That Needs Explaining

N/A

## Scope (locked at CP2, 06/10/2026)

Ranked within each tier. After CP2, scope changes need a conversation with the TA, not just a commit.

### Must-have

1. Click-to-earn **Work** button, mouse and keyboard ✅ *(CP2)*
2. Debt with automatic payments and per-second interest ✅ *(CP2)*
3. Upgrade shop with 5 upgrades, including a debt-funded Payday Loan ✅ *(CP2)*
4. Lose (bankruptcy) and win (debt-free CEO) conditions ✅ *(CP2)*
5. Quit / prestige with an Experience multiplier across 6 jobs ✅ *(CP2)*
6. Title screen that teaches the game, plus pause and end screens ✅ *(CP2)*
7. Tuning values and job data loaded from files in `data/` ✅ *(CP3)*
8. **Debt Collector** enemy: state machine (Away → Approaching → Collecting → Leaving) with scripted movement ✅ *(CP4)*
9. Simple sound effects: work click, purchase, loan, denied, quit, bankrupt ✅ *(CP3)*
10. Difficulty tuned from playtest data to a ~10-minute run ✅ *(CP5, bot data; human playtests at CP6)*

### Should-have

1. Debt Collector visits more often the more loans you hold. ✅ *(falls out of the CP4 design: loans raise debt)*
2. Unlock and purchase feedback (flash, number pop).
3. Late fee added to debt when the Debt Collector finds no cash. ✅ *(CP5)*

### Nice-to-have

1. Absurd bonus job titles after CEO for replay.
2. Simple background music loop.
3. Local save of best career time.

### Cut Line (not being built)

- Multiple debt sources or "loan shark" NPCs beyond the single Debt Collector
- Custom art (placeholder shapes only)
- Achievements system
- Cloud saves or user accounts
- A second prestige layer on top of Experience
- Leaderboards or multiplayer
