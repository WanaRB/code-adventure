extends Control

func _ready() -> void:
	_update_kunci()

func _update_kunci():
	# Temukan tombol berdasarkan nama fungsi sinyal pressed-nya
	for btn in find_children("*", "Button", true, false):
		if not btn is Button: continue
		for conn in btn.get_signal_connection_list("pressed"):
			var method: String = conn["callable"].get_method()
			if "level_2" in method:
				_terapkan_kunci(btn, 2)
			elif "level_3" in method:
				_terapkan_kunci(btn, 3)

func _terapkan_kunci(btn: Button, level: int):
	var terbuka := SaveManager.is_level_unlocked(level)
	btn.disabled = not terbuka
	if not terbuka and not btn.text.begins_with("🔒"):
		btn.text = "🔒 " + btn.text
	elif terbuka and btn.text.begins_with("🔒 "):
		btn.text = btn.text.substr(3)

func _on_button_level_1_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Tampilan/level_1.tscn")

func _on_button_level_2_pressed() -> void:
	if SaveManager.is_level_unlocked(2):
		get_tree().change_scene_to_file("res://scenes/Tampilan/level_2.tscn")

func _on_button_level_3_pressed() -> void:
	if SaveManager.is_level_unlocked(3):
		get_tree().change_scene_to_file("res://scenes/Tampilan/level_3.tscn")

func _on_button_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Tampilan/main_menu.tscn")
