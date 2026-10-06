package clocked_in

import "core:fmt"
import rl "vendor:raylib"

COLOR_BG     :: rl.Color{24, 26, 33, 255}
COLOR_PANEL  :: rl.Color{36, 39, 50, 255}
COLOR_BUTTON :: rl.Color{58, 63, 80, 255}
COLOR_HOVER  :: rl.Color{78, 85, 108, 255}
COLOR_TEXT   :: rl.Color{230, 232, 238, 255}
COLOR_MUTED  :: rl.Color{140, 146, 160, 255}
COLOR_CASH   :: rl.Color{110, 210, 130, 255}
COLOR_DEBT   :: rl.Color{235, 95, 90, 255}
COLOR_ACCENT :: rl.Color{240, 190, 80, 255}
COLOR_DARK   :: rl.Color{30, 30, 36, 255}

game_draw :: proc(g: Game) {
	rl.ClearBackground(COLOR_BG)

	switch g.state {
	case .Title:
		draw_title()

	case .Playing:
		draw_playing(g)

	case .Paused:
		draw_playing(g)
		draw_overlay(g, "PAUSED", "Enter, P or Esc to resume", "Q to quit to the title screen", false)

	case .Job_Complete:
		draw_playing(g)
		next := JOBS[g.job_index + 1]
		draw_overlay(
			g,
			"YOU QUIT!",
			fmt.tprintf("New job: %s, starting %s in debt", next.title, money(next.starting_debt)),
			fmt.tprintf("Experience is now x%.1f: every paycheck is bigger", xp_multiplier(g)),
			true,
		)

	case .Game_Over:
		draw_playing(g)
		draw_overlay(
			g,
			"BANKRUPT",
			fmt.tprintf("Interest buried you as a %s.", current_job(g).title),
			"Fewer loans, or Refinance sooner.",
			true,
		)

	case .Victory:
		draw_playing(g)
		draw_overlay(
			g,
			"DEBT-FREE CEO",
			fmt.tprintf("You clocked out for good in %s.", duration(g.career_time)),
			"Thanks for working here.",
			true,
		)
	}
}

draw_title :: proc() {
	cx: f32 = SCREEN_W / 2
	text_centered("CLOCKED IN", cx, 90, 72, COLOR_ACCENT)
	text_centered("Work your way out of debt, from Janitor to CEO.", cx, 175, 22, COLOR_TEXT)

	lines := [?]string {
		"Click WORK (or press Space) to earn money.",
		"Part of every paycheck pays down your debt automatically.",
		"Spend the rest on upgrades (click them, or keys 1-5).",
		"Payday Loans raise your pay, but they add debt.",
		"Interest grows your debt. If it doubles, you're bankrupt.",
		"Debt at zero? QUIT (Q) for a better job. Experience carries over.",
	}
	for line, i in lines {
		text_centered(line, cx, 250 + f32(i) * 32, 20, COLOR_MUTED)
	}

	if blink() {
		text_centered("Press Enter or click to start", cx, 480, 26, COLOR_TEXT)
	}
	text_centered("Esc / P pause    Q exit", cx, 540, 16, COLOR_MUTED)
}

draw_playing :: proc(g: Game) {
	draw_header(g)

	rl.DrawRectangleRounded(OFFICE_RECT, 0.03, 8, COLOR_PANEL)
	draw_debt_bar(g)
	text(fmt.tprintf("Coworkers %d/%d", g.owned[.Coworker], UPGRADES[.Coworker].max_owned), 32, 320, 18, COLOR_MUTED)
	text("Space", WORK_BUTTON_RECT.x + 84, WORK_BUTTON_RECT.y + WORK_BUTTON_RECT.height + 8, 16, COLOR_MUTED)

	for e in g.entities {
		draw_entity(e, g.tuning)
	}

	draw_upgrade_panel(g)
}

draw_header :: proc(g: Game) {
	rl.DrawRectangleRec(HEADER_RECT, COLOR_PANEL)
	job := current_job(g)
	text(fmt.tprintf("JOB %d/%d  %s", g.job_index + 1, len(JOBS), job.title), 16, 10, 24, COLOR_TEXT)
	text(fmt.tprintf("Experience x%.1f", xp_multiplier(g)), 16, 40, 16, COLOR_ACCENT)

	stat(g, "CASH", money(g.cash), 400, COLOR_CASH)
	stat(g, "PER CLICK", money(wage_per_click(g)), 590, COLOR_TEXT)
	stat(g, "COWORKERS", fmt.tprintf("%s/s", money(coworker_income_per_sec(g))), 770, COLOR_TEXT)
}

stat :: proc(g: Game, label, value: string, x: f32, color: rl.Color) {
	text(label, x, 8, 14, COLOR_MUTED)
	text(value, x, 26, 28, color)
}

draw_debt_bar :: proc(g: Game) {
	bar := DEBT_BAR_RECT
	limit := bankrupt_limit(g)
	rl.DrawRectangleRec(bar, COLOR_DARK)

	fill := bar
	fill.width = bar.width * f32(min(g.debt / limit, 1))
	rl.DrawRectangleRec(fill, COLOR_DEBT)

	// starting debt marker
	start_x := bar.x + bar.width * f32(g.starting_debt / limit)
	rl.DrawRectangle(i32(start_x), i32(bar.y) - 4, 2, i32(bar.height) + 8, COLOR_TEXT)

	y := bar.y + bar.height + 8
	if g.debt <= 0 {
		text("DEBT PAID! Quit (Q) for a better-paying job.", bar.x, y, 18, COLOR_CASH)
	} else {
		text(
			fmt.tprintf("Debt %s    Bankrupt at %s    Interest %.2f%%/s", money(g.debt), money(limit), interest_rate(g) * 100),
			bar.x, y, 18, COLOR_TEXT,
		)
	}
}

draw_entity :: proc(e: Entity, t: Tuning) {
	r := entity_rect(e)
	switch e.kind {
	case .Work_Button:
		color := COLOR_ACCENT
		if e.flash > 0 {
			r = grow(r, 6)
			color = rl.Color{255, 220, 120, 255}
		} else if hovered(r) {
			color = rl.Color{250, 205, 105, 255}
		}
		rl.DrawRectangleRounded(r, 0.25, 8, color)
		text_centered("WORK", r.x + r.width / 2, r.y + r.height / 2 - 20, 40, COLOR_DARK)

	case .Coworker:
		desk := e.flash > 0 ? COLOR_HOVER : COLOR_BUTTON
		rl.DrawRectangleRounded(r, 0.15, 6, desk)
		cx := r.x + r.width / 2
		rl.DrawCircleV({cx, r.y + 28}, 14, COLOR_ACCENT) // head
		rl.DrawRectangleRounded({cx - 22, r.y + 46, 44, 34}, 0.4, 6, COLOR_MUTED) // body
		if e.flash > 0 {
			rl.DrawRectangleRoundedLinesEx(r, 0.15, 6, 2, COLOR_CASH)
		}

	case .Popup:
		alpha := e.timer / t.popup_lifetime
		text_centered(fmt.tprintf("+%s", money(e.amount)), e.pos.x, e.pos.y, 22, rl.Fade(COLOR_CASH, alpha))
	}
}

draw_upgrade_panel :: proc(g: Game) {
	rl.DrawRectangleRounded(PANEL_RECT, 0.03, 8, COLOR_PANEL)
	text("UPGRADES", PANEL_RECT.x + 16, PANEL_RECT.y + 12, 20, COLOR_TEXT)

	for kind in Upgrade_Kind {
		draw_upgrade_button(g, kind)
	}

	r := QUIT_BUTTON_RECT
	if g.debt <= 0 {
		color := hovered(r) ? rl.Color{140, 230, 160, 255} : COLOR_CASH
		rl.DrawRectangleRounded(r, 0.2, 8, color)
		label := is_last_job(g) ? "RETIRE  [Q]" : "QUIT JOB  [Q]"
		text_centered(label, r.x + r.width / 2, r.y + 16, 24, COLOR_DARK)
	} else {
		rl.DrawRectangleRounded(r, 0.2, 8, COLOR_DARK)
		text_centered("Pay off your debt to quit", r.x + r.width / 2, r.y + 19, 18, COLOR_MUTED)
	}
}

draw_upgrade_button :: proc(g: Game, kind: Upgrade_Kind) {
	r := upgrade_rect(kind)
	def := UPGRADES[kind]
	status := purchase_status(g, kind)

	bg := COLOR_BUTTON
	if status == .Ok && hovered(r) do bg = COLOR_HOVER
	if status == .Locked do bg = COLOR_DARK
	rl.DrawRectangleRounded(r, 0.15, 6, bg)

	x := r.x + 12
	name_color := status == .Locked ? COLOR_MUTED : COLOR_TEXT
	text(fmt.tprintf("[%d] %s", int(kind) + 1, def.name), x, r.y + 8, 18, name_color)
	owned := fmt.tprintf("x%d", g.owned[kind])
	text(owned, r.x + r.width - 12 - text_width(owned, 18), r.y + 8, 18, COLOR_MUTED)
	text(def.blurb, x, r.y + 30, 14, COLOR_MUTED)

	cost := upgrade_cost(g, kind)
	price: string
	price_color := COLOR_MUTED
	switch status {
	case .Locked:
		price = fmt.tprintf("Unlocks at %.0f%% debt paid", def.unlock_at * 100)
	case .Maxed:
		price = "MAXED"
	case .Ok, .Too_Expensive:
		if def.is_loan {
			price = fmt.tprintf("+%s debt", money(cost))
			price_color = COLOR_DEBT
		} else {
			price = money(cost)
			if status == .Ok do price_color = COLOR_CASH
		}
	}
	text(price, x, r.y + 48, 16, price_color)
}

draw_overlay :: proc(g: Game, title, line1, line2: string, show_continue: bool) {
	rl.DrawRectangle(0, 0, SCREEN_W, SCREEN_H, rl.Fade(rl.BLACK, 0.65))
	box := rl.Rectangle{SCREEN_W / 2 - 300, SCREEN_H / 2 - 120, 600, 240}
	rl.DrawRectangleRounded(box, 0.08, 8, COLOR_PANEL)

	cx := box.x + box.width / 2
	text_centered(title, cx, box.y + 28, 44, COLOR_ACCENT)
	text_centered(line1, cx, box.y + 96, 20, COLOR_TEXT)
	text_centered(line2, cx, box.y + 128, 20, COLOR_MUTED)
	if show_continue && g.state_time >= END_SCREEN_DELAY && blink() {
		text_centered("Press Enter or click to continue", cx, box.y + 186, 20, COLOR_TEXT)
	}
}

// helpers

text :: proc(s: string, x, y: f32, size: i32, color: rl.Color) {
	rl.DrawText(fmt.ctprintf("%s", s), i32(x), i32(y), size, color)
}

text_width :: proc(s: string, size: i32) -> f32 {
	return f32(rl.MeasureText(fmt.ctprintf("%s", s), size))
}

text_centered :: proc(s: string, cx, y: f32, size: i32, color: rl.Color) {
	text(s, cx - text_width(s, size) / 2, y, size, color)
}

hovered :: proc(r: rl.Rectangle) -> bool {
	return rl.CheckCollisionPointRec(rl.GetMousePosition(), r)
}

grow :: proc(r: rl.Rectangle, by: f32) -> rl.Rectangle {
	return {r.x - by, r.y - by, r.width + by * 2, r.height + by * 2}
}

blink :: proc() -> bool {
	return int(rl.GetTime() * 2) % 2 == 0
}

money :: proc(v: f64) -> string {
	switch {
	case v >= 1e9:
		return fmt.tprintf("$%.2fB", v / 1e9)
	case v >= 1e6:
		return fmt.tprintf("$%.2fM", v / 1e6)
	case v >= 1e4:
		return fmt.tprintf("$%.1fK", v / 1e3)
	}
	return fmt.tprintf("$%.2f", v)
}

duration :: proc(seconds: f32) -> string {
	s := int(seconds)
	return fmt.tprintf("%dm %02ds", s / 60, s % 60)
}
