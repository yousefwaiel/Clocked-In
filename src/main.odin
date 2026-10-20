package clocked_in

import rl "vendor:raylib"

main :: proc() {
	rl.InitWindow(SCREEN_W, SCREEN_H, "Clocked In")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)
	rl.SetExitKey(.KEY_NULL) // esc = pause

	game: Game
	if !game_init(&game) {
		return
	}
	defer game_destroy(&game)

	assets := assets_load()
	defer assets_unload(&assets)
	rl.SetMasterVolume(game.tuning.volume)

	for !rl.WindowShouldClose() && !game.should_exit {
		actions := input_poll()
		game_update(&game, actions, rl.GetFrameTime())
		play_sounds(assets, game.sounds)

		rl.BeginDrawing()
		game_draw(game)
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}
}
