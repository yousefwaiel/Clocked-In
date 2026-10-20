package clocked_in

import rl "vendor:raylib"

Sound_Id :: enum {
	Work,
	Buy,
	Loan,
	Denied,
	Quit,
	Bankrupt,
}

SOUND_FILES := [Sound_Id]cstring {
	.Work     = "assets/sounds/click_001.ogg",
	.Buy      = "assets/sounds/handleCoins2.ogg",
	.Loan     = "assets/sounds/handleCoins.ogg",
	.Denied   = "assets/sounds/error_004.ogg",
	.Quit     = "assets/sounds/confirmation_002.ogg",
	.Bankrupt = "assets/sounds/error_006.ogg",
}

// loaded once at startup, shared by everything
Assets :: struct {
	sounds: [Sound_Id]rl.Sound,
}

assets_load :: proc() -> Assets {
	rl.InitAudioDevice()
	a: Assets
	for path, id in SOUND_FILES {
		a.sounds[id] = rl.LoadSound(path)
	}
	return a
}

assets_unload :: proc(a: ^Assets) {
	for s in a.sounds {
		rl.UnloadSound(s)
	}
	rl.CloseAudioDevice()
}

play_sounds :: proc(a: Assets, sounds: bit_set[Sound_Id]) {
	for id in sounds {
		rl.PlaySound(a.sounds[id])
	}
}
