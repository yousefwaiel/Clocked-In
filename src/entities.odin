package clocked_in

import "core:math/rand"
import rl "vendor:raylib"

// everything in the office
Entity_Kind :: enum {
	Work_Button,
	Coworker,
	Popup, // +$ text
}

Entity :: struct {
	kind:   Entity_Kind,
	pos:    rl.Vector2, // top left
	size:   rl.Vector2,
	vel:    rl.Vector2,
	timer:  f32, // next click / time left
	flash:  f32, // highlight time
	amount: f64,
}

spawn_work_button :: proc(g: ^Game) {
	r := WORK_BUTTON_RECT
	append(&g.entities, Entity{kind = .Work_Button, pos = {r.x, r.y}, size = {r.width, r.height}})
}

spawn_coworker :: proc(g: ^Game, slot: int) {
	r := coworker_slot_rect(slot)
	// stagger so they don't sync
	first_click := g.tuning.coworker_interval * (0.3 + 0.1 * f32(slot))
	append(&g.entities, Entity{kind = .Coworker, pos = {r.x, r.y}, size = {r.width, r.height}, timer = first_click})
}

spawn_popup :: proc(g: ^Game, at: rl.Vector2, amount: f64) {
	append(&g.entities, Entity {
		kind   = .Popup,
		pos    = at + {rand.float32_range(-40, 40), -20},
		vel    = {0, -60},
		timer  = g.tuning.popup_lifetime,
		amount = amount,
	})
}

find_entity :: proc(g: ^Game, kind: Entity_Kind) -> ^Entity {
	for &e in g.entities {
		if e.kind == kind {
			return &e
		}
	}
	return nil
}

entity_rect :: proc(e: Entity) -> rl.Rectangle {
	return {e.pos.x, e.pos.y, e.size.x, e.size.y}
}

entity_center :: proc(e: Entity) -> rl.Vector2 {
	return e.pos + e.size / 2
}

update_entities :: proc(g: ^Game, dt: f32) {
	// index loop, append can move the array
	count := len(g.entities)
	for i in 0 ..< count {
		e := &g.entities[i]
		e.flash = max(e.flash - dt, 0)

		switch e.kind {
		case .Work_Button:
		// nothing

		case .Coworker:
			e.timer -= dt
			if e.timer <= 0 {
				e.timer += g.tuning.coworker_interval
				e.flash = 0.15
				at := entity_center(e^)
				amount := coworker_click_value(g^)
				earn(g, amount)
				spawn_popup(g, at, amount) // don't use e after this
			}

		case .Popup:
			e.pos += e.vel * dt
			e.timer -= dt
		}
	}

	// remove dead popups (backwards)
	for i := len(g.entities) - 1; i >= 0; i -= 1 {
		e := g.entities[i]
		if e.kind == .Popup && e.timer <= 0 {
			unordered_remove(&g.entities, i)
		}
	}
}
