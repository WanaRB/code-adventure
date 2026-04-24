extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_kembali_ke_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Tampilan/main_menu.tscn")



func _on_retry_pressed() -> void:
	if GameEvents.last_level_path != "":
			# Memuat ulang level terakhir yang disimpan
		get_tree().change_scene_to_file(GameEvents.last_level_path)
	else:
			# Fallback jika terjadi error, kembali ke Level 1
		get_tree().change_scene_to_file("res://scenes/Level1.tscn")
