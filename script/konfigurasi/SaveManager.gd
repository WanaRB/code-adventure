extends Node

# Data hanya di memori — reset otomatis tiap kali game dibuka (sistem sesi)
var _max_level_unlocked := 1
var _level_results := {
	"1": { "correct": 0, "bonus": 0, "wrong": 0, "item_pts": 0, "played": false },
	"2": { "correct": 0, "bonus": 0, "wrong": 0, "item_pts": 0, "played": false },
	"3": { "correct": 0, "bonus": 0, "wrong": 0, "item_pts": 0, "played": false },
}

func unlock_level(level: int):
	if level > _max_level_unlocked:
		_max_level_unlocked = level

func is_level_unlocked(level: int) -> bool:
	return level <= _max_level_unlocked

func get_max_unlocked() -> int:
	return _max_level_unlocked

func save_level_result(level: int, correct: int, bonus: int, wrong: int, item_pts: int):
	_level_results[str(level)] = {
		"correct":  correct,
		"bonus":    bonus,
		"wrong":    wrong,
		"item_pts": item_pts,
		"played":   true,
	}

func get_level_result(level: int) -> Dictionary:
	# Selalu kembalikan dict lengkap dengan semua key agar tidak crash
	var r: Dictionary = _level_results.get(str(level), {})
	return {
		"correct":  int(r.get("correct",  0)),
		"bonus":    int(r.get("bonus",    0)),
		"wrong":    int(r.get("wrong",    0)),
		"item_pts": int(r.get("item_pts", 0)),
		"played":   bool(r.get("played",  false)),
	}

func get_level_net_points(level: int) -> int:
	var r := get_level_result(level)
	return max(0, r["correct"] * 100 + r["bonus"] + r["item_pts"] - r["wrong"] * 10)

func get_total_points() -> int:
	var total := 0
	for k in ["1", "2", "3"]:
		total += get_level_net_points(int(k))
	return total

func reset():
	_max_level_unlocked = 1
	for k in ["1", "2", "3"]:
		_level_results[k] = { "correct": 0, "bonus": 0, "wrong": 0, "item_pts": 0, "played": false }
	print("SaveManager: reset ke awal")
