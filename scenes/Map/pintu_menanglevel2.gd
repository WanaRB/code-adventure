extends Area2D

@export var door_id: int = 1
@onready var sprite = $Sprite2D

var is_open = false
var player_di_dekat_pintu = false

func _ready():
	GameEvents.quiz_answered_correct.connect(_on_quiz_solved)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.frame = 1

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_di_dekat_pintu = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_di_dekat_pintu = false

func _on_quiz_solved(quiz_id):
	if quiz_id == door_id:
		is_open = true
		sprite.frame = 0

func _input(event):
	# Jika tombol E ditekan, player didekat pintu, dan kuis sudah benar
	if event.is_action_pressed("interact") and player_di_dekat_pintu and is_open:
		ke_halaman_menang()

func ke_halaman_menang():
	# Memindahkan player dari level ke layar kemenangan
	get_tree().change_scene_to_file("res://scenes/Tampilan/menang.tscn")
