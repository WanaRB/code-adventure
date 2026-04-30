extends Control

@export var ikon_suara_hidup: Texture2D
@export var ikon_suara_mati: Texture2D

func _ready() -> void:
	_update_kunci()
	_tambah_tombol_suara()

func _tambah_tombol_suara() -> void:
	var btn := TextureButton.new()
	btn.name = "TombolSuara"
	var ikon := ikon_suara_hidup if GameEvents.musik_menu_hidup else ikon_suara_mati
	btn.texture_normal  = ikon
	btn.texture_pressed = ikon
	btn.texture_hover   = ikon
	btn.ignore_texture_size = true
	btn.custom_minimum_size = Vector2(80, 80)
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn.offset_left   = -100.0
	btn.offset_top    = -160.0
	btn.offset_right  = -20.0
	btn.offset_bottom = -80.0
	btn.pressed.connect(func(): _toggle_suara(btn))
	add_child(btn)

func _toggle_suara(btn: TextureButton) -> void:
	GameEvents.musik_menu_hidup = not GameEvents.musik_menu_hidup
	var bgm := get_tree().root.get_node_or_null("BgmMenu")
	if GameEvents.musik_menu_hidup:
		if bgm: bgm.play()
		btn.texture_normal  = ikon_suara_hidup
		btn.texture_pressed = ikon_suara_hidup
		btn.texture_hover   = ikon_suara_hidup
	else:
		if bgm: bgm.stop()
		btn.texture_normal  = ikon_suara_mati
		btn.texture_pressed = ikon_suara_mati
		btn.texture_hover   = ikon_suara_mati

func _stop_bgm() -> void:
	var bgm := get_tree().root.get_node_or_null("BgmMenu")
	if bgm: bgm.stop()
	
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
	_stop_bgm()
	get_tree().change_scene_to_file("res://scenes/Level/level_1.tscn")

func _on_button_level_2_pressed() -> void:
	_stop_bgm()
	if SaveManager.is_level_unlocked(2):
		get_tree().change_scene_to_file("res://scenes/Level/level_2.tscn")

func _on_button_level_3_pressed() -> void:
	_stop_bgm()
	if SaveManager.is_level_unlocked(3):
		get_tree().change_scene_to_file("res://scenes/Level/level_3.tscn")

func _on_button_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/main_menu.tscn")
