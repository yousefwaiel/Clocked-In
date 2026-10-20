package clocked_in

import "core:encoding/json"
import "core:fmt"
import "core:os"

TUNING_PATH   :: "data/tuning.json"
JOBS_PATH     :: "data/jobs.json"
UPGRADES_PATH :: "data/upgrades.json"

load_json :: proc(path: string, out: ^$T) -> bool {
	bytes, err := os.read_entire_file(path, context.temp_allocator)
	if err != nil {
		fmt.eprintfln("can't read %s (%v), run from the repo root", path, err)
		return false
	}
	if json_err := json.unmarshal(bytes, out); json_err != nil {
		fmt.eprintfln("bad json in %s: %v", path, json_err)
		return false
	}
	return true
}

load_data :: proc(g: ^Game) -> bool {
	load_json(TUNING_PATH, &g.tuning) or_return
	load_json(JOBS_PATH, &g.jobs) or_return
	load_json(UPGRADES_PATH, &g.upgrades) or_return

	if len(g.jobs) == 0 {
		fmt.eprintfln("%s has no jobs", JOBS_PATH)
		return false
	}
	for def, kind in g.upgrades {
		if def.name == "" {
			fmt.eprintfln("%s is missing %v", UPGRADES_PATH, kind)
			return false
		}
	}
	return true
}

unload_data :: proc(g: ^Game) {
	for job in g.jobs {
		delete(job.title)
	}
	delete(g.jobs)
	for def in g.upgrades {
		delete(def.name)
		delete(def.blurb)
	}
}
