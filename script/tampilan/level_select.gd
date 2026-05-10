extends Control

@export var ikon_suara_hidup: Texture2D
@export var ikon_suara_mati: Texture2D
@onready var vbox: VBoxContainer = $VBoxContainer

func _ready() -> void:
	_animasi_masuk()
	_update_kunci()

func _stop_bgm() -> void:
	var bgm := get_tree().root.get_node_or_null("BgmMenu")
	if bgm: bgm.stop()
	
func _update_kunci():
	for btn in find_children("*", "Button", true, false):
		if not btn is Button: continue
		for conn in btn.get_signal_connection_list("pressed"):
			var method: String = conn["callable"].get_method()
			if "level_2" in method:
				_terapkan_kunci(btn, 2)
			elif "level_3" in method:
				_terapkan_kunci(btn, 3)
			elif "level_4" in method:
				_terapkan_kunci(btn, 4)
			elif "level_5" in method:
				_terapkan_kunci(btn, 5)

func _terapkan_kunci(btn: Button, level: int):
	var terbuka := SaveManager.is_level_unlocked(level)
	btn.disabled = not terbuka

func _on_button_level_1_pressed() -> void:
	_stop_bgm()
	_animasi_keluar("res://scenes/Level/level_1.tscn")

func _on_button_level_2_pressed() -> void:
	if SaveManager.is_level_unlocked(2):
		_stop_bgm()
		_animasi_keluar("res://scenes/Level/level_2.tscn")

func _on_button_level_3_pressed() -> void:
	if SaveManager.is_level_unlocked(3):
		_stop_bgm()
		_animasi_keluar("res://scenes/Level/level_3.tscn")

func _on_button_level_4_pressed() -> void:
	if SaveManager.is_level_unlocked(4):
		_stop_bgm()
		_animasi_keluar("res://scenes/Level/level_4.tscn")

func _on_button_level_5_pressed() -> void:
	if SaveManager.is_level_unlocked(5):
		_stop_bgm()
		_animasi_keluar("res://scenes/Level/level_5.tscn")

func _on_button_back_pressed() -> void:
	_animasi_keluar("res://scenes/UI/play_menu.tscn")

func _animasi_masuk() -> void:
	vbox.modulate.a = 0.0
	vbox.position.y += 600.0
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.1)
	tw.tween_property(vbox, "modulate:a", 1.0, 0.5)
	tw.parallel().tween_property(vbox, "position:y", vbox.position.y - 600.0, 0.7)
	tw.tween_callback(func(): vbox.mouse_filter = Control.MOUSE_FILTER_STOP)

func _animasi_keluar(target_scene: String) -> void:
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(vbox, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(vbox, "position:y", vbox.position.y + 600.0, 0.4)
	tw.tween_callback(func(): get_tree().change_scene_to_file(target_scene))
