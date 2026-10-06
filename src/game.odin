package clocked_in

Game_State :: enum {
	Title,
	Playing,
	Paused,
	Job_Complete,
	Game_Over,
	Victory,
}

// so you don't click past end screens
END_SCREEN_DELAY :: 0.6

Game :: struct {
	state:          Game_State,
	state_time:     f32,
	tuning:         Tuning,
	entities:       [dynamic]Entity,

	// kept between jobs
	jobs_completed: int,
	career_time:    f32,

	// reset every job
	job_index:      int,
	cash:           f64,
	debt:           f64,
	starting_debt:  f64,
	owned:          [Upgrade_Kind]int,
	unlocked:       [Upgrade_Kind]bool,

	should_exit:    bool,
}

game_init :: proc() -> Game {
	g := Game {
		state  = .Title,
		tuning = default_tuning(),
	}
	start_job(&g, 0)
	return g
}

game_destroy :: proc(g: ^Game) {
	delete(g.entities)
}

set_state :: proc(g: ^Game, state: Game_State) {
	g.state = state
	g.state_time = 0
}

new_career :: proc(g: ^Game) {
	g.jobs_completed = 0
	g.career_time = 0
	start_job(g, 0)
}

start_job :: proc(g: ^Game, index: int) {
	g.job_index = index
	g.starting_debt = JOBS[index].starting_debt
	g.debt = g.starting_debt
	g.cash = 0
	g.owned = {}
	g.unlocked = {}
	clear(&g.entities)
	spawn_work_button(g)
	refresh_unlocks(g)
}

game_update :: proc(g: ^Game, actions: Actions, dt: f32) {
	g.state_time += dt
	end_screen_ready := g.state_time >= END_SCREEN_DELAY

	switch g.state {
	case .Title:
		if .Confirm in actions {
			new_career(g)
			set_state(g, .Playing)
		} else if .Quit in actions {
			g.should_exit = true
		}

	case .Playing:
		update_playing(g, actions, dt)

	case .Paused:
		if .Pause in actions || .Confirm in actions {
			set_state(g, .Playing)
		} else if .Quit in actions {
			set_state(g, .Title)
		}

	case .Job_Complete:
		if .Confirm in actions && end_screen_ready {
			start_job(g, g.job_index + 1)
			set_state(g, .Playing)
		}

	case .Game_Over, .Victory:
		if .Confirm in actions && end_screen_ready {
			set_state(g, .Title)
		}
	}
}

update_playing :: proc(g: ^Game, actions: Actions, dt: f32) {
	if .Pause in actions {
		set_state(g, .Paused)
		return
	}
	g.career_time += dt

	if .Work in actions {
		work_click(g)
	}
	for kind in Upgrade_Kind {
		if buy_action(kind) in actions {
			try_buy(g, kind)
		}
	}
	if .Quit in actions && g.debt <= 0 {
		quit_job(g)
		return
	}

	update_entities(g, dt)

	g.debt += g.debt * interest_rate(g^) * f64(dt)
	refresh_unlocks(g)

	if g.debt >= bankrupt_limit(g^) {
		set_state(g, .Game_Over)
	}
}

work_click :: proc(g: ^Game) {
	amount := wage_per_click(g^)
	earn(g, amount)
	button := find_entity(g, .Work_Button)
	button.flash = 0.1
	spawn_popup(g, entity_center(button^), amount)
}

// part to debt, rest to cash
earn :: proc(g: ^Game, amount: f64) {
	payment := min(amount * payment_share(g^), g.debt)
	g.debt -= payment
	g.cash += amount - payment
	if g.debt < 0.005 {
		g.debt = 0 // rounding
	}
}

try_buy :: proc(g: ^Game, kind: Upgrade_Kind) {
	if purchase_status(g^, kind) != .Ok {
		return
	}
	cost := upgrade_cost(g^, kind)
	if UPGRADES[kind].is_loan {
		g.debt += cost
	} else {
		g.cash -= cost
	}
	g.owned[kind] += 1
	if kind == .Coworker {
		spawn_coworker(g, g.owned[.Coworker] - 1)
	}
}

refresh_unlocks :: proc(g: ^Game) {
	for kind in Upgrade_Kind {
		if paid_fraction(g^) >= UPGRADES[kind].unlock_at {
			g.unlocked[kind] = true
		}
	}
}

quit_job :: proc(g: ^Game) {
	g.jobs_completed += 1
	if is_last_job(g^) {
		set_state(g, .Victory)
	} else {
		set_state(g, .Job_Complete)
	}
}
