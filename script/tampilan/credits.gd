extends Control

@export var ikon_suara_hidup: Texture2D
@export var ikon_suara_mati: Texture2D

func _ready() -> void:
	pass

func _on_button_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/main_menu.tscn")
