package clocked_in

import rl "vendor:raylib"

SCREEN_W :: 960
SCREEN_H :: 600

HEADER_RECT      :: rl.Rectangle{0, 0, SCREEN_W, 64}
OFFICE_RECT      :: rl.Rectangle{16, 80, 600, 504}
DEBT_BAR_RECT    :: rl.Rectangle{32, 96, 568, 24}
WORK_BUTTON_RECT :: rl.Rectangle{206, 170, 220, 120}
PANEL_RECT       :: rl.Rectangle{632, 80, 312, 504}
QUIT_BUTTON_RECT :: rl.Rectangle{648, 512, 280, 56}

COWORKER_COLUMNS :: 4

upgrade_rect :: proc(kind: Upgrade_Kind) -> rl.Rectangle {
	return {648, 120 + f32(int(kind)) * 76, 280, 68}
}

coworker_slot_rect :: proc(slot: int) -> rl.Rectangle {
	col := f32(slot % COWORKER_COLUMNS)
	row := f32(slot / COWORKER_COLUMNS)
	return {48 + col * 140, 350 + row * 110, 120, 90}
}
