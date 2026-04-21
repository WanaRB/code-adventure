extends Area2D

@export var data_kuis: QuizResource
@export var scene_ui_kuis: PackedScene
@export var target_door_id: int = 1 
# TAMBAHKAN INI: Agar tiap laptop bisa punya aksi berbeda (misal: "convert_drones")
@export var action_to_trigger: String = "convert_drones" 

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
	instance_kuis.set_door_id(target_door_id) 
	
	# PENTING: Kirim nama aksi dari laptop ini ke UI kuis
	if "action_to_trigger" in instance_kuis:
		instance_kuis.action_to_trigger = action_to_trigger
	
	get_tree().paused = true
