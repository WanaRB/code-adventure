extends Node

# Sinyal untuk memberitahu HUD kapan harus bersembunyi
signal quiz_opened
signal quiz_closed

# Sinyal untuk menambah skor atau mengurangi darah [cite: 4, 28]
signal score_changed(new_score)
signal health_changed(new_health)

# TAMBAHKAN SINYAL BARU INI
signal quiz_answered_correct(id:int, action_name:String) # ID digunakan jika ada banyak pintu

signal player_hit(damage_amount)
var last_level_path: String = ""
