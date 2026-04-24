extends Area2D

@export var data_kuis: QuizResource
@export var scene_ui_kuis: PackedScene

var player_didalam_area = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_didalam_area = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_didalam_area = false

func _input(event):
	if event.is_action_pressed("interact") and player_didalam_area:
		buka_kuis()

func buka_kuis():
	GameEvents.quiz_opened.emit()
	var instance_kuis = scene_ui_kuis.instantiate()
	get_tree().root.add_child(instance_kuis)
	instance_kuis.setup_quiz(data_kuis)
	get_tree().paused = true
