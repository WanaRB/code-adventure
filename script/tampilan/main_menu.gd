extends Control

func _ready() -> void:
	pass

func _on_button_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Tampilan/level_1.tscn")

func _on_button_level_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Tampilan/level_select.tscn")

func _on_button_credit_pressed() -> void:
	pass

func _on_button_exit_pressed() -> void:
	if OS.has_feature("web"):
		# HTML5: tampilkan konfirmasi lalu tutup tab via JavaScript
		JavaScriptBridge.eval("""
			if (confirm('Yakin ingin keluar dari game?')) {
				window.close();
			}
		""")
	else:
		# Desktop: langsung quit
		get_tree().quit()
