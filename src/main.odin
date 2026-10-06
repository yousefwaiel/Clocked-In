package clocked_in

import rl "vendor:raylib"

main :: proc() {
	rl.InitWindow(SCREEN_W, SCREEN_H, "Clocked In")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)
	rl.SetExitKey(.KEY_NULL) // esc = pause

	game := game_init()
	defer game_destroy(&game)

	for !rl.WindowShouldClose() && !game.should_exit {
		actions := input_poll()
		game_update(&game, actions, rl.GetFrameTime())

		rl.BeginDrawing()
		game_draw(game)
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}
}
