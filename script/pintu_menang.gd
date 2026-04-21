extends Area2D

@export var door_id: int = 1
@onready var sprite = $Sprite2D
@export_file("*.tscn") var target_level_path: String

var is_open = false
var player_di_dekat_pintu = false

func _ready():
	# Pastikan sinyal terhubung ke fungsi dengan 2 parameter
	GameEvents.quiz_answered_correct.connect(_on_quiz_solved)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.frame = 1 # Frame pintu tertutup

func _on_quiz_solved(quiz_id: int, _action_name: String):
	# DEBUG: Hapus tanda komentar di bawah ini jika ingin cek di Output
	# print("Pintu menerima kuis ID: ", quiz_id, " | Door ID saya: ", door_id)
	
	if quiz_id == door_id:
		is_open = true
		sprite.frame = 0 # Visual pintu terbuka
		# print("Pintu Berhasil Terbuka!")

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_di_dekat_pintu = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_di_dekat_pintu = false

func _input(event):
	if event.is_action_pressed("interact") and player_di_dekat_pintu and is_open:
		eksekusi_pindah_level()

func eksekusi_pindah_level():
	if target_level_path == "":
		return
	get_tree().call_deferred("change_scene_to_file", target_level_path)
