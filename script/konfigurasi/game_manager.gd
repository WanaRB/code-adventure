extends Node

@onready var point_label: Label = %Point_Label
@onready var h_box_darah          = %darah.get_node("HBoxContainer")
@onready var hit_sfx: AudioStreamPlayer = %HitSfx

var health := 3
var session_correct  := 0
var session_bonus    := 0
var session_wrong    := 0
var session_item_pts := 0   # Poin dari item apel dll
var current_level    := 1

func _ready():
	GameEvents.player_hit.connect(_on_player_hit)
	GameEvents.quiz_points_earned.connect(_on_quiz_points_earned)
	GameEvents.item_collected.connect(_on_item_collected)   # FIX: connect yang hilang
	GameEvents.level_won.connect(_on_level_won)
	GameEvents.last_level_path = get_tree().current_scene.scene_file_path
	current_level = _detect_level()
	update_ui()

func _detect_level() -> int:
	var path := GameEvents.last_level_path
	if "level_3" in path: return 3
	if "level_2" in path: return 2
	return 1

func _on_quiz_points_earned(correct: int, bonus: int, wrong: int):
	session_correct += correct
	session_bonus   += bonus
	session_wrong   += wrong
	update_ui()

func _on_item_collected(points: int):   # FIX: fungsi yang hilang
	session_item_pts += points
	update_ui()

func _on_level_won():
	SaveManager.save_level_result(
		current_level, session_correct, session_bonus, session_wrong, session_item_pts)

func _on_player_hit(amount: int):
	health -= amount
	if hit_sfx: hit_sfx.play()
	update_ui()
	if health <= 0:
		# FIX: simpan poin sesi ke GameEvents sebelum pindah scene
		# agar lose_screen bisa membacanya
		GameEvents.last_session_net = get_session_net()
		get_tree().call_deferred("change_scene_to_file", "res://scenes/Tampilan/LoseScreen.tscn")

func get_session_net() -> int:   # FIX: session_item_pts ikut dihitung
	return max(0,
		session_correct  * 100
		+ session_bonus
		+ session_item_pts
		- session_wrong  * 10)

func update_ui():
	if point_label:
		point_label.text = "Poin: %d" % get_session_net()
	if h_box_darah:
		var darah := h_box_darah.get_children()
		for i in range(darah.size()):
			darah[i].visible = i < health
