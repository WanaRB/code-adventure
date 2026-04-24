extends Node

# ─── Sinyal Quiz ──────────────────────────────────────────────────────────────
signal quiz_opened
signal quiz_closed

## Dipancarkan ketika semua highlight pada satu soal dijawab benar.
## Tiap script yang ingin bereaksi terhadap perubahan dunia harus
## connect ke sinyal ini lalu cek isi array world_changes.
signal quiz_answered_correct(world_changes: Array)

# ─── Sinyal Player ────────────────────────────────────────────────────────────
signal player_hit(damage_amount: int)

# ─── State Global ─────────────────────────────────────────────────────────────
var last_level_path: String = ""
