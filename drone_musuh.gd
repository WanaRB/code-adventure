extends CharacterBody2D

@export var kecepatan: float = 100.0
@export var jarak_patroli: float = 200.0 
@export var bisa_jadi_baik: bool = false 
# Tambahkan ini: Pilihan arah di Inspector
@export var mulai_ke_kiri: bool = false 

@onready var hurt_box_collision = $HurtBox/CollisionShape2D
@onready var sprite = $AnimatedSprite2D

var batas_kiri: float
var batas_kanan: float
var arah: int = 1 
var is_friendly = false

func _ready():
	GameEvents.quiz_answered_correct.connect(_on_quiz_solved)
	
	# SETUP ARAH DAN BATAS PATROLI
	if mulai_ke_kiri:
		arah = -1
		sprite.flip_h = true
		# Jika mulai ke kiri, posisi awal adalah titik paling kanan
		batas_kanan = global_position.x
		batas_kiri = global_position.x - jarak_patroli
	else:
		arah = 1
		sprite.flip_h = false
		# Jika mulai ke kanan, posisi awal adalah titik paling kiri
		batas_kiri = global_position.x
		batas_kanan = global_position.x + jarak_patroli
	
	sprite.play("walk")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_priority = 10.0

	if has_node("HurtBox"):
		$HurtBox.body_entered.connect(_on_hurt_box_body_entered)
	
	# SETUP FISIKA
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, false)

func _on_quiz_solved(_quiz_id: int, action_name: String):
	if bisa_jadi_baik and action_name == "convert_drones":
		become_friendly()

func become_friendly():
	is_friendly = true
	modulate = Color(0, 0.7, 1)
	if hurt_box_collision:
		hurt_box_collision.set_deferred("disabled", true)
	set_collision_mask_value(2, false)
	set_collision_layer_value(3, false)
	set_collision_layer_value(1, true) 

func _on_hurt_box_body_entered(body):
	if not is_friendly and body.is_in_group("player"):
		body.take_damage(1, global_position)

func _physics_process(_delta):
	velocity.x = arah * kecepatan
	move_and_slide()
	
	# Logika patroli menggunakan batas yang sudah dikalkulasi
	if global_position.x >= batas_kanan:
		arah = -1
		sprite.flip_h = true
	elif global_position.x <= batas_kiri:
		arah = 1
		sprite.flip_h = false
