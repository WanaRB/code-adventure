extends CharacterBody2D

@export var kecepatan: float = 100.0
@export var jarak_patroli: float = 200.0 

@onready var hurt_box_collision = $HurtBox/CollisionShape2D
@onready var sprite = $AnimatedSprite2D

var posisi_awal: float
var arah = 1 
var is_friendly = false

func _ready():
	GameEvents.quiz_answered_correct.connect(_on_quiz_solved)
	posisi_awal = global_position.x
	sprite.play("walk")
	$HurtBox.body_entered.connect(_on_hurt_box_body_entered)
	
	# SETUP FISIKA OTOMATIS (Mencegah drone tabrakan satu sama lain)
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true) # Drone di Layer 3
	set_collision_mask_value(1, true)  # Drone hanya menabrak Lantai (Layer 1) agar tidak jatuh/hilang
	# Mask ke Layer 3 (sesama drone) tidak diaktifkan agar bisa saling menembus

func _on_quiz_solved(quiz_id):
	if quiz_id == 1: 
		become_friendly()

func become_friendly():
	is_friendly = true
	modulate = Color(0, 0.7, 1) 
	if hurt_box_collision:
		hurt_box_collision.set_deferred("disabled", true)
	
	# Tetap berada di Layer 3 dan menabrak Lantai (Layer 1)
	# Player tetap bisa naik karena Mask Player mendeteksi Layer 3

func _on_hurt_box_body_entered(body):
	if not is_friendly and body.is_in_group("player"):
		body.take_damage(1, global_position)

func _physics_process(delta):
	velocity.x = arah * kecepatan
	move_and_slide()
	
	if global_position.x >= posisi_awal + jarak_patroli:
		arah = -1 
		sprite.flip_h = true 
	elif global_position.x <= posisi_awal:
		arah = 1 
		sprite.flip_h = false
