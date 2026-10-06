package clocked_in

import "core:testing"

// odin test src

start_playing :: proc() -> Game {
	g := game_init()
	game_update(&g, {.Confirm}, 0)
	return g
}

near :: proc(a, b: f64) -> bool {
	return abs(a - b) < 1e-9
}

@(test)
title_starts_the_game :: proc(t: ^testing.T) {
	g := game_init()
	defer game_destroy(&g)
	testing.expect_value(t, g.state, Game_State.Title)
	game_update(&g, {.Confirm}, 0)
	testing.expect_value(t, g.state, Game_State.Playing)
}

@(test)
work_splits_pay_between_debt_and_cash :: proc(t: ^testing.T) {
	g := start_playing()
	defer game_destroy(&g)
	wage := wage_per_click(g)
	game_update(&g, {.Work}, 0)
	testing.expect(t, near(g.cash, wage * 0.5))
	testing.expect(t, near(g.debt, g.starting_debt - wage * 0.5))
}

@(test)
pause_freezes_interest :: proc(t: ^testing.T) {
	g := start_playing()
	defer game_destroy(&g)
	game_update(&g, {.Pause}, 0)
	testing.expect_value(t, g.state, Game_State.Paused)
	debt := g.debt
	game_update(&g, {}, 10)
	testing.expect(t, near(g.debt, debt))
	game_update(&g, {.Pause}, 0)
	testing.expect_value(t, g.state, Game_State.Playing)
}

@(test)
payday_loan_adds_debt_and_raises_pay :: proc(t: ^testing.T) {
	g := start_playing()
	defer game_destroy(&g)
	wage := wage_per_click(g)
	cost := upgrade_cost(g, .Payday_Loan)
	game_update(&g, {.Buy_5}, 0)
	testing.expect_value(t, g.owned[.Payday_Loan], 1)
	testing.expect(t, near(g.debt, g.starting_debt + cost))
	testing.expect(t, near(wage_per_click(g), wage * 1.5))
}

@(test)
cannot_buy_without_cash :: proc(t: ^testing.T) {
	g := start_playing()
	defer game_destroy(&g)
	game_update(&g, {.Buy_1}, 0)
	testing.expect_value(t, g.owned[.Coworker], 0)
}

@(test)
coworker_is_an_entity_and_earns :: proc(t: ^testing.T) {
	g := start_playing()
	defer game_destroy(&g)
	g.cash = 100
	game_update(&g, {.Buy_1}, 0)
	testing.expect_value(t, g.owned[.Coworker], 1)
	testing.expect(t, find_entity(&g, .Coworker) != nil)

	cash := g.cash
	game_update(&g, {}, 1.0)
	testing.expect(t, g.cash > cash)
}

@(test)
interest_bankrupts_you :: proc(t: ^testing.T) {
	g := start_playing()
	defer game_destroy(&g)
	g.debt = bankrupt_limit(g)
	game_update(&g, {}, 0)
	testing.expect_value(t, g.state, Game_State.Game_Over)
}

@(test)
quit_needs_zero_debt_and_keeps_experience :: proc(t: ^testing.T) {
	g := start_playing()
	defer game_destroy(&g)

	game_update(&g, {.Quit}, 0)
	testing.expect_value(t, g.state, Game_State.Playing)

	g.debt = 0
	g.cash = 999
	game_update(&g, {.Quit}, 0)
	testing.expect_value(t, g.state, Game_State.Job_Complete)

	game_update(&g, {.Confirm}, 0) // too soon
	testing.expect_value(t, g.state, Game_State.Job_Complete)
	game_update(&g, {}, END_SCREEN_DELAY)
	game_update(&g, {.Confirm}, 0)

	testing.expect_value(t, g.state, Game_State.Playing)
	testing.expect_value(t, g.job_index, 1)
	testing.expect(t, near(g.cash, 0))
	testing.expect(t, near(g.debt, JOBS[1].starting_debt))
	testing.expect(t, near(xp_multiplier(g), 1.5))
}

@(test)
paying_off_the_last_job_wins :: proc(t: ^testing.T) {
	g := start_playing()
	defer game_destroy(&g)
	start_job(&g, len(JOBS) - 1)
	g.debt = 0
	game_update(&g, {.Quit}, 0)
	testing.expect_value(t, g.state, Game_State.Victory)
}

@(test)
upgrades_unlock_as_debt_is_paid :: proc(t: ^testing.T) {
	g := start_playing()
	defer game_destroy(&g)
	testing.expect(t, !g.unlocked[.Refinance])
	g.debt = g.starting_debt * 0.5
	game_update(&g, {}, 0)
	testing.expect(t, g.unlocked[.Refinance])
}
