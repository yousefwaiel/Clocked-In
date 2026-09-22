# Clocked In - Game Design Document

**Student Name:** Yousef Waiel Said  
**Student ID:** 100857349  
**Date:** 22/10/2026  
**Class:** CSCI 4160U Game Development  
**Repository Link:**  

## Description

### Description

**Clocked In** is a debt-payoff clicker game. At the start of every “job,” you begin with a large amount of debt. You click the **Work** icon to earn wages, and a portion of the money you make is automatically used to pay down your debt. You can spend the money left over on upgrades that either increase your income or help reduce your debt faster.

There is one exception: **loan-advance upgrades**. These upgrades give you a big boost to your income right away, but they also increase the amount of debt you have to pay back.

Once you completely pay off your debt, you can choose to **Quit** and move on to a new, better-paying job. Quitting resets your cash and debt back to zero, but you keep a permanent **Experience multiplier** earned from your previous career progress. This multiplier makes every future job faster to complete.

## Core Gameplay Loop

### The Gameplay Loop

1. Click **Work** → earn cents.
2. A portion of your income automatically goes toward debt.
3. Spend leftover cash on upgrades.
4. Decide whether to take a loan-advance upgrade for faster income or choose a safer upgrade.
5. Pay off the debt.
6. **Quit** and start a new job.
7. Cash and debt reset while your **Experience multiplier** carries over.
8. Repeat the process, with each job becoming faster.

## Primary Mechanics

The main mechanic is clicking the **Work** icon to generate currency.

## Secondary Mechanics

Players can spend their earned currency on upgrades. These include:

- Auto-clickers / coworkers
- Income multipliers
- Debt-reduction tools
- Loan advances that trade additional debt for faster income

## Tertiary Mechanics

The **Quit / New Job prestige system** allows players to reset their current progress after paying off their debt. In return, they gain a permanent **Experience multiplier** based on their career earnings. This multiplier applies to all future jobs.

## MDA Framework

### Mechanics

The game uses a click-to-earn currency system, with a fixed percentage of income automatically going toward debt payments.

Players can purchase upgrades from a shop, which includes both safe upgrades and loan-based upgrades.

The debt counter can either increase when the player takes a loan or decrease as they make payments.

The prestige system resets the player’s current money and debt while giving the player a permanent multiplier.

### Dynamics

The main tension comes from deciding whether it is better to play safely and slowly or take on more debt in exchange for faster progress. Players should constantly be thinking about how much additional debt they can take on before it becomes a problem.

The prestige system also creates a rubber-band effect where the first few jobs feel slower, but each reset makes future jobs faster and allows the player to clear their debt in less time.

### Aesthetics

The game focuses mainly on **Challenge**, as players have to decide when taking a loan is actually worth it.

There is also an element of **Fantasy**, as players work their way up from a low-paying job into a career.

**Expression** comes from allowing players to choose their own playstyle, whether they want to be more careful and save money or take bigger risks with loans.

## Player Experience

### How should they feel? (Incorporate LeBlanc’s Taxonomy of Pleasures)

The game should mainly provide a feeling of **Submission**, through the simple and satisfying experience of watching numbers continuously go up, along with **Challenge**, especially when deciding whether or not to take on more debt.

There is also some **Fantasy** involved in working your way up the career ladder.

The debt system is meant to create a small amount of anxiety that normal clicker games do not have. However, it should still feel light-hearted and relatable rather than overly difficult or punishing.

## Game Inspirations

- **Cookie Clicker**
- **Universal Paperclips**
- **Adventure Capitalist**

## Non-Game Inspirations

- Debt-payoff and budgeting apps that use progress bars
- “First to save/spend a million” style YouTube challenge videos
- Gig-economy and paycheck-to-paycheck culture and memes

## Genre

**Incremental / idle resource-management**

The main idea is that the player is grinding their way out of debt, rather than simply clicking for the sake of clicking.

## Target Audience

### Incorporate Bartle’s Taxonomy

The main target audience is **Achievers**, since the game is built around reaching payoff milestones and unlocking new job titles.

There is also some appeal for **Explorers**, especially for players who enjoy figuring out the best way to balance safe upgrades with loan-based upgrades.

## Progression Over Time

The player starts with **Job 1**, which represents a minimum-wage job. The jobs will have names that progress from **Janitor → CEO**.

As the player’s debt decreases, they unlock a small selection of upgrades.

Once the debt is fully paid off, the player unlocks the ability to **Quit** and move on to the next job.

Each new job starts with a larger amount of debt and provides a higher wage. However, the player’s permanent **Experience multiplier** makes each new job faster to complete than the previous one.

The job titles also become more absurd as the player continues to prestige, providing a small humorous reward for repeatedly completing jobs.

## Themes

The game is about the grind of living paycheck to paycheck and trying to work your way out of debt.

The topic is presented with a bit of tongue-in-cheek humor rather than being overly serious or depressing.

## Platform & Tools

## Anything Else Unusual That Needs Explaining

N/A

## Scope

### Keeping

- Click-to-earn **Work** button
- Debt counter with automatic payments based on income
- One upgrade list with around 5–6 upgrades, including auto-clickers, income multipliers, and loan advances
- One **Quit / prestige** tier with an Experience multiplier
- Minimal UI with money, debt, and Experience readouts, along with one upgrade panel

### Cut Line

- Multiple debt sources or “loan shark” NPCs
- Sound design or music
- Custom art, using placeholder shapes instead
- Achievements system
- Cloud saves or user accounts
- Multiple prestige / job tiers
- Leaderboards or multiplayer
