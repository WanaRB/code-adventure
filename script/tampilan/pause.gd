extends Node
@onready var pause_panel: Panel = %pause_panel
@onready var check_fullscreen: OptionButton = %CheckFullscreen

func _ready() -> void:
	pause_panel.hide()
	add_to_group("pause_controller")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_pause_btn_pressed()

func _on_resume_pressed():
	pause_panel.hide()
	get_tree().paused = false

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/UI/main_menu.tscn")

func _on_pause_btn_pressed() -> void:
	# Sync state sebelum tampil
	var is_fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	GameEvents.is_fullscreen = is_fs
	check_fullscreen.set_block_signals(true)
	check_fullscreen.selected = 1 if is_fs else 0
	check_fullscreen.set_block_signals(false)
	get_tree().paused = true
	pause_panel.show()

func _on_fullscreen_item_selected(index: int) -> void:
	
	var toggled_on := index == 1
	GameEvents.is_fullscreen = toggled_on
	if OS.has_feature("web"):
		if toggled_on:
			JavaScriptBridge.eval("var el=document.documentElement;if(el.requestFullscreen)el.requestFullscreen();")
		else:
			JavaScriptBridge.eval("if(document.exitFullscreen)document.exitFullscreen();")
	else:
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on else DisplayServer.WINDOW_MODE_WINDOWED
		DisplayServer.window_set_mode(mode)


func _on_check_fullscreen_item_selected(index: int) -> void:
	pass # Replace with function body.
