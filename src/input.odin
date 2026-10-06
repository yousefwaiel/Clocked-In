package clocked_in

import rl "vendor:raylib"

Action :: enum {
	Work,
	Buy_1,
	Buy_2,
	Buy_3,
	Buy_4,
	Buy_5,
	Quit, // depends on state
	Pause,
	Confirm,
}

Actions :: bit_set[Action]

BUY_KEYS := [Upgrade_Kind]rl.KeyboardKey {
	.Coworker    = .ONE,
	.Overtime    = .TWO,
	.Budget_App  = .THREE,
	.Refinance   = .FOUR,
	.Payday_Loan = .FIVE,
}

#assert(int(Action.Buy_5) - int(Action.Buy_1) + 1 == len(Upgrade_Kind))

buy_action :: proc(kind: Upgrade_Kind) -> Action {
	return Action(int(Action.Buy_1) + int(kind))
}

input_poll :: proc() -> Actions {
	actions: Actions

	if rl.IsKeyPressed(.SPACE) do actions += {.Work}
	if rl.IsKeyPressed(.ENTER) do actions += {.Confirm}
	if rl.IsKeyPressed(.ESCAPE) || rl.IsKeyPressed(.P) do actions += {.Pause}
	if rl.IsKeyPressed(.Q) do actions += {.Quit}

	for kind in Upgrade_Kind {
		if rl.IsKeyPressed(BUY_KEYS[kind]) do actions += {buy_action(kind)}
	}

	if rl.IsMouseButtonPressed(.LEFT) {
		actions += {.Confirm}
		mouse := rl.GetMousePosition()
		if rl.CheckCollisionPointRec(mouse, WORK_BUTTON_RECT) do actions += {.Work}
		if rl.CheckCollisionPointRec(mouse, QUIT_BUTTON_RECT) do actions += {.Quit}
		for kind in Upgrade_Kind {
			if rl.CheckCollisionPointRec(mouse, upgrade_rect(kind)) do actions += {buy_action(kind)}
		}
	}

	return actions
}
