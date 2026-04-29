extends Node
@onready var pause_panel: Panel = %pause_panel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("pause_controller")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var esc_pressed = Input.is_action_just_pressed("pause")
	if (esc_pressed == true):
		get_tree().paused = true
		pause_panel.show()


func _on_resume_pressed():
	pause_panel.hide()
	get_tree().paused = false


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/UI/main_menu.tscn")

func _on_pause_btn_pressed() -> void:
	# Dipanggil oleh tombol pause mobile
	get_tree().paused = true
	pause_panel.show()
