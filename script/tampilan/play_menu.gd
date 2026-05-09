extends Control

@onready var vbox: VBoxContainer = $VBoxContainer
@onready var button_continue: Button = $VBoxContainer/button_continue

@export var ikon_suara_hidup: Texture2D
@export var ikon_suara_mati: Texture2D

func _ready() -> void:
	_setup_bgm()
	_setup_continue()
	_animasi_masuk()

func _setup_continue() -> void:
	var pernah_main: bool = SaveManager.get_level_result(1)["played"]
	if not pernah_main:
		button_continue.disabled = true
		button_continue.modulate = Color(0.6, 0.6, 0.6, 0.6)

func _animasi_masuk() -> void:
	vbox.modulate.a = 0.0
	vbox.position.y += 600.0
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.1)
	tw.tween_property(vbox, "modulate:a", 1.0, 0.4)
	tw.parallel().tween_property(vbox, "position:y", vbox.position.y - 600.0, 0.5)
	tw.tween_callback(func(): vbox.mouse_filter = Control.MOUSE_FILTER_STOP)

func _animasi_keluar(target_scene: String) -> void:
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(vbox, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(vbox, "position:y", vbox.position.y + 600.0, 0.4)
	tw.tween_callback(func(): get_tree().change_scene_to_file(target_scene))

func _on_button_new_game_pressed() -> void:
	_stop_bgm()
	get_tree().change_scene_to_file("res://scenes/Level/level_1.tscn")

func _on_button_continue_pressed() -> void:
	if button_continue.disabled: return
	_stop_bgm()
	var max_level := SaveManager.get_max_unlocked()
	get_tree().change_scene_to_file("res://scenes/Level/level_%d.tscn" % max_level)

func _on_button_level_select_pressed() -> void:
	_animasi_keluar("res://scenes/UI/level_select.tscn")

func _on_button_back_pressed() -> void:
	_animasi_keluar("res://scenes/UI/main_menu.tscn")

func _stop_bgm() -> void:
	var bgm := get_tree().root.get_node_or_null("BgmMenu")
	if bgm: bgm.stop()

func _setup_bgm() -> void:
	var existing := get_tree().root.get_node_or_null("BgmMenu")
	if existing == null:
		return
	if has_node("BgmMenu"):
		$BgmMenu.queue_free()
	if GameEvents.musik_menu_hidup and not existing.playing:
		existing.play()
	elif not GameEvents.musik_menu_hidup:
		existing.stop()
