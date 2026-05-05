extends Node

# ─── Konfigurasi ──────────────────────────────────────────────────────────────
## Path file save. Di web export, tersimpan di localStorage browser.
## Di desktop, tersimpan di folder AppData/user data Godot.
const SAVE_PATH := "user://save.json"

# ─── State (di memori) ────────────────────────────────────────────────────────
var _max_level_unlocked := 1
var _level_results := {
	"1": { "correct": 0, "bonus": 0, "wrong": 0, "item_pts": 0, "played": false },
	"2": { "correct": 0, "bonus": 0, "wrong": 0, "item_pts": 0, "played": false },
	"3": { "correct": 0, "bonus": 0, "wrong": 0, "item_pts": 0, "played": false },
	"4": { "correct": 0, "bonus": 0, "wrong": 0, "item_pts": 0, "played": false },
	"5": { "correct": 0, "bonus": 0, "wrong": 0, "item_pts": 0, "played": false },
}

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	## Load otomatis saat game dibuka
	load_from_file()

# ─── API Publik (tidak berubah dari versi sebelumnya) ─────────────────────────
func unlock_level(level: int) -> void:
	if level > _max_level_unlocked:
		_max_level_unlocked = level
		save_to_file()  # simpan otomatis saat level baru terbuka

func is_level_unlocked(level: int) -> bool:
	return level <= _max_level_unlocked

func get_max_unlocked() -> int:
	return _max_level_unlocked

func save_level_result(level: int, correct: int, bonus: int, wrong: int, item_pts: int) -> void:
	_level_results[str(level)] = {
		"correct":  correct,
		"bonus":    bonus,
		"wrong":    wrong,
		"item_pts": item_pts,
		"played":   true,
	}
	save_to_file()  # simpan otomatis setelah selesai level

func get_level_result(level: int) -> Dictionary:
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
	for k in ["1", "2", "3", "4", "5"]:
		total += get_level_net_points(int(k))
	return total

func reset() -> void:
	_max_level_unlocked = 1
	for k in ["1", "2", "3", "4", "5"]:
		_level_results[k] = { "correct": 0, "bonus": 0, "wrong": 0, "item_pts": 0, "played": false }
	save_to_file()  # simpan state reset ke file

# ─── File Save / Load ─────────────────────────────────────────────────────────
## Simpan progress ke file JSON.
## Dipanggil otomatis saat unlock_level, save_level_result, dan reset.
func save_to_file() -> void:
	var data := {
		"max_level_unlocked": _max_level_unlocked,
		"level_results":      _level_results,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: gagal membuka file untuk ditulis — %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data))
	file.close()

## Load progress dari file JSON.
## Dipanggil otomatis saat game dibuka (_ready).
## Jika file tidak ada atau rusak, mulai dari awal tanpa error.
func load_from_file() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return  # belum pernah main, mulai dari awal

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: file save ditemukan tapi tidak bisa dibaca")
		return

	var raw := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw)
	if parsed == null or not parsed is Dictionary:
		push_warning("SaveManager: file save rusak, mulai dari awal")
		return

	# Restore data — gunakan .get() agar tidak crash jika key tidak ada
	_max_level_unlocked = int(parsed.get("max_level_unlocked", 1))
	var saved_results: Dictionary = parsed.get("level_results", {})
	for k in ["1", "2", "3", "4", "5"]:
		if saved_results.has(k):
			_level_results[k] = saved_results[k]
