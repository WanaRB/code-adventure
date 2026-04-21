extends Area2D

@export var door_id: int = 1
@onready var sprite = $Sprite2D
@export_file("*.tscn") var target_level_path: String

var is_open = false
var player_di_dekat_pintu = false

func _ready():
	GameEvents.quiz_answered_correct.connect(_on_quiz_solved)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Set frame pintu tertutup di awal
	sprite.frame = 1

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_di_dekat_pintu = true
		# JANGAN panggil pindah_scene() di sini

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_di_dekat_pintu = false

func _on_quiz_solved(quiz_id):
	if quiz_id == door_id:
		is_open = true
		sprite.frame = 0 # Visual pintu terbuka

func _input(event):
	# Pengecekan tiga kondisi sekaligus sebelum pindah level
	if event.is_action_pressed("interact") and player_di_dekat_pintu and is_open:
		eksekusi_pindah_level()

func eksekusi_pindah_level():
	if target_level_path == "" or target_level_path == null:
		print("Error: Target level belum diatur di Inspector!")
		return
		
	# Gunakan variabel target_level_path, jangan di-hardcode
	get_tree().call_deferred("change_scene_to_file", target_level_path)
