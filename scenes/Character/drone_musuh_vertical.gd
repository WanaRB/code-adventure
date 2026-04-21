extends CharacterBody2D

@export var kecepatan: float = 100.0
@export var jarak_patroli: float = 200.0 
@export var bisa_jadi_baik: bool = false 

@onready var sprite = $AnimatedSprite2D
@onready var hurt_box_collision = $HurtBox/CollisionShape2D 

var posisi_awal: float
var arah = 1 # 1 untuk bawah, -1 untuk atas
var is_friendly = false

func _ready():
	GameEvents.quiz_answered_correct.connect(_on_quiz_solved)
	posisi_awal = global_position.y
	sprite.play("walk") 
	
	# 1. Mode Floating: Menghilangkan algoritma snapping lantai internal
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	
	# 2. Prioritas Tinggi: Drone tidak akan 'mengalah' saat terjadi konflik fisika
	collision_priority = 10.0

	if has_node("HurtBox"):
		$HurtBox.body_entered.connect(_on_hurt_box_body_entered)

	# SETUP FISIKA AWAL
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true) # Drone di Layer 3 (Enemy)
	set_collision_mask_value(1, true)  # Drone menabrak dinding/lantai map (Layer 1)
	
	# KUNCI UTAMA: Matikan Mask ke Player (Layer 2). 
	# Drone tidak akan berhenti saat menyentuh Jikri.
	set_collision_mask_value(2, false)
	
func _on_quiz_solved(_quiz_id: int, action_name: String):
	if bisa_jadi_baik and action_name == "convert_drones":
		become_friendly()

func become_friendly():
	is_friendly = true
	modulate = Color(0, 0.7, 1)
	
	if hurt_box_collision:
		hurt_box_collision.set_deferred("disabled", true)
	
	# Tetap matikan mask ke Player agar tidak terhenti oleh beban Jikri
	set_collision_mask_value(2, false)
	
	# Pindahkan drone ke Layer 1 (World) agar Jikri bisa menapak dengan stabil
	set_collision_layer_value(3, false)
	set_collision_layer_value(1, true) 

func _on_hurt_box_body_entered(body):
	if not is_friendly and body.is_in_group("player"):
		body.take_damage(1, global_position)

func _physics_process(_delta):
	# Velocity tetap diproses secara konstan
	velocity.y = arah * kecepatan
	
	# Bergerak tanpa menghiraukan objek di Layer 2 (Jikri)
	move_and_slide()
	
	# Logika Patroli
	if global_position.y >= posisi_awal + jarak_patroli:
		arah = -1
	elif global_position.y <= posisi_awal:
		arah = 1
