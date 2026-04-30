extends Node

signal quiz_opened
signal quiz_closed
signal quiz_answered_correct(world_changes: Array)
signal quiz_points_earned(correct_count: int, speed_bonus: int, wrong_count: int)
signal item_collected(points: int)
signal player_hit(damage_amount: int)
signal level_won
signal game_over
## State suara menu — true = hidup, false = mati. Dibaca semua scene menu.
var musik_menu_hidup: bool = true


var last_level_path: String = ""

## Poin sesi terakhir — diisi game_manager, dibaca lose_screen
var last_session_net: int = 0
