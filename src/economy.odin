package clocked_in

import "core:math"

// TODO move to data/ for CP3

Job :: struct {
	title:         string,
	starting_debt: f64,
	wage:          f64, // per click
}

JOBS := [?]Job {
	{"Janitor", 50, 0.25},
	{"Barista", 400, 1.0},
	{"Intern", 3_000, 4.0},
	{"Cubicle Drone", 25_000, 16.0},
	{"Middle Manager", 200_000, 64.0},
	{"CEO", 1_500_000, 256.0},
}

Upgrade_Kind :: enum {
	Coworker,
	Overtime,
	Budget_App,
	Refinance,
	Payday_Loan,
}

Upgrade_Def :: struct {
	name:        string,
	blurb:       string,
	base_cost:   f64, // janitor price
	cost_growth: f64,
	max_owned:   int,
	unlock_at:   f64, // % paid to unlock
	is_loan:     bool, // costs debt not cash
}

UPGRADES := [Upgrade_Kind]Upgrade_Def {
	.Coworker    = {"Hire Coworker", "Works for you once a second", 1.0, 1.4, 8, 0.0, false},
	.Overtime    = {"Overtime", "+25% pay per click", 2.0, 1.6, 10, 0.0, false},
	.Budget_App  = {"Budget App", "+10% of pay goes to debt", 3.0, 1.8, 4, 0.15, false},
	.Refinance   = {"Refinance", "Interest rate x0.7", 5.0, 2.0, 3, 0.30, false},
	.Payday_Loan = {"Payday Loan", "Pay x1.5, but adds debt", 0, 1.5, 4, 0.0, true},
}

Tuning :: struct {
	payment_share:      f64, // % to debt
	payment_share_step: f64,
	payment_share_max:  f64,
	interest_per_sec:   f64,
	refinance_factor:   f64,
	bankrupt_factor:    f64, // lose at debt * this
	overtime_bonus:     f64,
	loan_wage_mult:     f64,
	loan_debt_fraction: f64,
	coworker_interval:  f32, // seconds
	coworker_share:     f64,
	xp_per_job:         f64,
	popup_lifetime:     f32,
}

default_tuning :: proc() -> Tuning {
	return Tuning {
		payment_share      = 0.5,
		payment_share_step = 0.1,
		payment_share_max  = 0.9,
		interest_per_sec   = 0.003,
		refinance_factor   = 0.7,
		bankrupt_factor    = 2.0,
		overtime_bonus     = 0.25,
		loan_wage_mult     = 1.5,
		loan_debt_fraction = 0.4,
		coworker_interval  = 1.0,
		coworker_share     = 0.5,
		xp_per_job         = 0.5,
		popup_lifetime     = 0.8,
	}
}

current_job :: proc(g: Game) -> Job {
	return JOBS[g.job_index]
}

is_last_job :: proc(g: Game) -> bool {
	return g.job_index == len(JOBS) - 1
}

xp_multiplier :: proc(g: Game) -> f64 {
	return 1 + g.tuning.xp_per_job * f64(g.jobs_completed)
}

wage_per_click :: proc(g: Game) -> f64 {
	t := g.tuning
	wage := current_job(g).wage
	wage *= 1 + t.overtime_bonus * f64(g.owned[.Overtime])
	wage *= math.pow(t.loan_wage_mult, f64(g.owned[.Payday_Loan]))
	return wage * xp_multiplier(g)
}

coworker_click_value :: proc(g: Game) -> f64 {
	return wage_per_click(g) * g.tuning.coworker_share
}

coworker_income_per_sec :: proc(g: Game) -> f64 {
	return f64(g.owned[.Coworker]) * coworker_click_value(g) / f64(g.tuning.coworker_interval)
}

payment_share :: proc(g: Game) -> f64 {
	t := g.tuning
	share := t.payment_share + t.payment_share_step * f64(g.owned[.Budget_App])
	return min(share, t.payment_share_max)
}

interest_rate :: proc(g: Game) -> f64 {
	t := g.tuning
	return t.interest_per_sec * math.pow(t.refinance_factor, f64(g.owned[.Refinance]))
}

bankrupt_limit :: proc(g: Game) -> f64 {
	return g.starting_debt * g.tuning.bankrupt_factor
}

paid_fraction :: proc(g: Game) -> f64 {
	return 1 - g.debt / g.starting_debt
}

upgrade_cost :: proc(g: Game, kind: Upgrade_Kind) -> f64 {
	def := UPGRADES[kind]
	growth := math.pow(def.cost_growth, f64(g.owned[kind]))
	if def.is_loan {
		return g.starting_debt * g.tuning.loan_debt_fraction * growth
	}
	job_scale := current_job(g).wage / JOBS[0].wage
	return def.base_cost * job_scale * growth
}

Purchase_Status :: enum {
	Ok,
	Locked,
	Maxed,
	Too_Expensive,
}

purchase_status :: proc(g: Game, kind: Upgrade_Kind) -> Purchase_Status {
	def := UPGRADES[kind]
	switch {
	case !g.unlocked[kind]:
		return .Locked
	case g.owned[kind] >= def.max_owned:
		return .Maxed
	case !def.is_loan && g.cash < upgrade_cost(g, kind):
		return .Too_Expensive
	}
	return .Ok
}
