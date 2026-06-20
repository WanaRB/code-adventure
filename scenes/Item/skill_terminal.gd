extends Area2D

@export var scene_ui_skill: PackedScene

var player_didalam_area := false
var _terminal_terbuka := false
var _label_interaksi: Node2D = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameEvents.skill_terminal_closed.connect(func(): _terminal_terbuka = false)
	_buat_label_interaksi()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_didalam_area = true
		if _label_interaksi:
			_label_interaksi.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_didalam_area = false
		if _label_interaksi:
			_label_interaksi.visible = false

func _input(event):
	if event.is_action_pressed("interact") and player_didalam_area:
		buka_terminal()

func buka_terminal():
	if _terminal_terbuka: return
	_terminal_terbuka = true
	var instance := scene_ui_skill.instantiate()
	get_tree().root.add_child(instance)
	get_tree().paused = true

func _buat_label_interaksi() -> void:
	var container := Node2D.new()
	container.position = Vector2(0, -90)
	container.visible = false
	add_child(container)
	_label_interaksi = container
	var label := Label.new()
	label.text = "Tekan [E] untuk konfigurasi skill"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 4)
	label.position = Vector2(-110, -10)
	container.add_child(label)
