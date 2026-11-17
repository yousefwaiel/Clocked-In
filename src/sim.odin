package clocked_in

import "core:fmt"
import "core:os"
import "core:strings"

// headless playtest bots for balancing
// ./build/clocked_in --sim <label>  ->  playtests/sim_<label>.csv

SIM_DT :: 1.0 / 60
SIM_MAX_TIME :: 30 * 60 // give up after 30 min
SIM_THINK_TIME :: 0.5 // bots look at the shop twice a second

Strategy :: enum {
	Saver, // never borrows
	Careful, // borrows while debt stays under the collector
	Bold, // borrows up to 1.5x starting debt
	Reckless, // takes every loan
}

Bot :: struct {
	strategy: Strategy,
	cps:      f32, // clicks per second
}

Job_Result :: struct {
	job:        int,
	seconds:    f32,
	outcome:    string,
	loans:      int,
	visits:     int,
	collected:  f64,
	peak_ratio: f64,
}

run_sims :: proc() {
	label := len(os.args) > 2 ? os.args[2] : "latest"

	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	fmt.sbprintln(&b, "strategy,cps,job,title,seconds,outcome,loans,collector_visits,cash_collected,peak_debt_ratio")

	fmt.printfln("%-9s %-4s %-8s %-15s %-7s %s", "strategy", "cps", "career", "reached", "visits", "result")
	for strategy in Strategy {
		for cps in ([]f32{4, 5, 6, 7}) {
			bot := Bot{strategy, cps}
			results := sim_career(bot)
			defer delete(results)

			total: f32
			visits: int
			last := results[len(results) - 1]
			for r in results {
				total += r.seconds
				visits += r.visits
				fmt.sbprintfln(&b, "%v,%v,%d,%s,%.1f,%s,%d,%d,%.2f,%.3f",
					strategy, cps, r.job + 1, sim_job_title(r.job), r.seconds, r.outcome,
					r.loans, r.visits, r.collected, r.peak_ratio)
			}
			fmt.printfln("%-9v %-4v %-8s %-15s %-7v %s",
				strategy, cps, duration(total), sim_job_title(last.job), visits, last.outcome)
		}
	}

	os.make_directory_all("playtests")
	path := fmt.tprintf("playtests/sim_%s.csv", label)
	if err := os.write_entire_file(path, strings.to_string(b)); err != nil {
		fmt.eprintfln("can't write %s (%v)", path, err)
		return
	}
	fmt.println("wrote", path)
}

sim_job_titles: [dynamic]string

sim_job_title :: proc(i: int) -> string {
	return i < len(sim_job_titles) ? sim_job_titles[i] : "?"
}

sim_career :: proc(bot: Bot) -> [dynamic]Job_Result {
	g: Game
	if !game_init(&g) {
		os.exit(1)
	}
	defer game_destroy(&g)
	if len(sim_job_titles) == 0 {
		for j in g.jobs do append(&sim_job_titles, strings.clone(j.title))
	}

	game_update(&g, {.Confirm}, 0)

	results: [dynamic]Job_Result
	r := Job_Result{peak_ratio = 1}
	click_timer, think_timer: f32
	last_state := Collector_State.Away

	for g.career_time < SIM_MAX_TIME {
		actions: Actions

		#partial switch g.state {
		case .Job_Complete:
			game_update(&g, {}, END_SCREEN_DELAY)
			game_update(&g, {.Confirm}, 0)
			r = Job_Result{job = g.job_index, peak_ratio = 1}
			continue
		case .Victory, .Game_Over:
			return results
		}

		click_timer += SIM_DT
		if click_timer >= 1 / bot.cps {
			click_timer -= 1 / bot.cps
			actions += {.Work}
		}

		think_timer += SIM_DT
		if think_timer >= SIM_THINK_TIME {
			think_timer = 0
			if g.debt <= 0 {
				actions += {.Quit}
			} else if kind, ok := bot_pick(g, bot.strategy); ok {
				actions += {buy_action(kind)}
				if kind == .Payday_Loan do r.loans += 1
			}
		}

		game_update(&g, actions, SIM_DT)
		free_all(context.temp_allocator)

		r.seconds += SIM_DT
		r.peak_ratio = max(r.peak_ratio, debt_ratio(g))
		r.collected = g.cash_collected
		state := collector_state(g)
		if state == .Collecting && last_state != .Collecting {
			r.visits += 1
		}
		last_state = state

		#partial switch g.state {
		case .Job_Complete, .Victory:
			r.outcome = "quit"
			append(&results, r)
		case .Game_Over:
			r.outcome = "bankrupt"
			append(&results, r)
		}
	}

	r.outcome = "timeout"
	append(&results, r)
	return results
}

// what would this bot buy right now
bot_pick :: proc(g: Game, strategy: Strategy) -> (Upgrade_Kind, bool) {
	switch strategy {
	case .Saver:
	case .Careful, .Bold:
		limit := strategy == .Careful ? g.tuning.collector_approach_at : 1.5
		if purchase_status(g, .Payday_Loan) == .Ok {
			after := (g.debt + upgrade_cost(g, .Payday_Loan)) / g.starting_debt
			if after < limit {
				return .Payday_Loan, true
			}
		}
	case .Reckless:
		if purchase_status(g, .Payday_Loan) == .Ok {
			return .Payday_Loan, true
		}
	}

	for kind in ([]Upgrade_Kind{.Refinance, .Budget_App}) {
		if purchase_status(g, kind) == .Ok {
			return kind, true
		}
	}

	// cheapest of the income upgrades
	best: Maybe(Upgrade_Kind)
	for kind in ([]Upgrade_Kind{.Coworker, .Overtime}) {
		if purchase_status(g, kind) != .Ok do continue
		if b, ok := best.?; !ok || upgrade_cost(g, kind) < upgrade_cost(g, b) {
			best = kind
		}
	}
	if b, ok := best.?; ok {
		return b, true
	}
	return {}, false
}
