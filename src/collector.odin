package clocked_in

import "core:math/linalg"
import rl "vendor:raylib"

Collector_State :: enum {
	Away,
	Approaching,
	Collecting,
	Leaving,
}

// door -> corridor -> under the cash counter
COLLECTOR_PATH := [?]rl.Vector2{{600, 300}, {560, 300}, {560, 200}}
COLLECTOR_SIZE :: rl.Vector2{32, 52}

spawn_collector :: proc(g: ^Game) {
	e := Entity {
		kind = .Collector,
		size = COLLECTOR_SIZE,
	}
	e.pos = path_point(0) - e.size / 2
	append(&g.entities, e)
}

update_collector :: proc(g: ^Game, e: ^Entity, dt: f32) {
	t := g.tuning
	ratio := debt_ratio(g^)

	switch e.collector {
	case .Away:
		if ratio >= t.collector_approach_at {
			set_collector_state(g, e, .Approaching)
		}

	case .Approaching:
		// how far along the path he should be depends on how much you owe
		span := t.collector_collect_at - t.collector_approach_at
		target := f32(clamp((ratio - t.collector_approach_at) / span, 0, 1))
		e.progress = move_toward(e.progress, target, t.collector_speed * dt)

		if ratio < t.collector_leave_at {
			set_collector_state(g, e, .Leaving)
		} else if e.progress >= 1 {
			set_collector_state(g, e, .Collecting)
		}

	case .Collecting:
		taken := g.cash * t.collector_take_rate * f64(dt)
		g.cash -= taken
		g.cash_collected += taken
		g.debt = max(g.debt - taken * (1 - t.collector_fee), 0) // he keeps a fee
		if g.cash < g.starting_debt * 0.01 {
			g.debt += g.starting_debt * t.collector_late_fee * f64(dt) // nothing to take
		}

		if ratio < t.collector_leave_at {
			set_collector_state(g, e, .Leaving)
		}

	case .Leaving:
		e.progress = move_toward(e.progress, 0, t.collector_speed * dt)
		if e.progress <= 0 {
			set_collector_state(g, e, .Away)
		}
	}

	e.pos = path_point(e.progress) - e.size / 2
}

set_collector_state :: proc(g: ^Game, e: ^Entity, state: Collector_State) {
	if state == .Collecting {
		g.sounds += {.Collected}
	}
	e.collector = state
}

collector_state :: proc(g: Game) -> Collector_State {
	for e in g.entities {
		if e.kind == .Collector {
			return e.collector
		}
	}
	return .Away
}

// 0 = at the door, 1 = at your cash
path_point :: proc(progress: f32) -> rl.Vector2 {
	total: f32
	for i in 1 ..< len(COLLECTOR_PATH) {
		total += linalg.distance(COLLECTOR_PATH[i - 1], COLLECTOR_PATH[i])
	}

	dist := progress * total
	for i in 1 ..< len(COLLECTOR_PATH) {
		a, b := COLLECTOR_PATH[i - 1], COLLECTOR_PATH[i]
		seg := linalg.distance(a, b)
		if dist <= seg {
			return a + (b - a) * (dist / seg)
		}
		dist -= seg
	}
	return COLLECTOR_PATH[len(COLLECTOR_PATH) - 1]
}

move_toward :: proc(current, target, step: f32) -> f32 {
	if current < target {
		return min(current + step, target)
	}
	return max(current - step, target)
}
