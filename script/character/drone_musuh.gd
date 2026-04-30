extends CharacterBody2D

# Untuk sorot drone saat konversi, tempatkan WorldChangeMarker node
# di tengah kerumunan drone di scene, set marker_action = CONVERT_DRONES.
# drone_musuh.gd sendiri tidak mengurus kamera — WorldChangeMarker yang mengurus.

@export var kecepatan: float = 100.0
@export var jarak_patroli: float = 200.0
@export var bisa_jadi_baik: bool = false
@export var mulai_ke_kiri: bool = false

## [Opsional] Suara drone berubah jadi baik.
## Tambahkan AudioStreamPlayer2D sebagai child, drag ke sini.
@export var sfx_konversi: AudioStreamPlayer2D

@onready var hurt_box_collision = $HurtBox/CollisionShape2D
@onready var sprite = $AnimatedSprite2D

var batas_kiri: float
var batas_kanan: float
var arah: int = 1
var is_friendly := false

func _ready():
	GameEvents.quiz_answered_correct.connect(_on_quiz_solved)

	if mulai_ke_kiri:
		arah = -1
		sprite.flip_h = true
		batas_kanan = global_position.x
		batas_kiri = global_position.x - jarak_patroli
	else:
		arah = 1
		sprite.flip_h = false
		batas_kiri = global_position.x
		batas_kanan = global_position.x + jarak_patroli

	update_animation()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_priority = 10.0

	if has_node("HurtBox"):
		$HurtBox.body_entered.connect(_on_hurt_box_body_entered)

	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, false)

func _on_quiz_solved(world_changes: Array):
	for entry: WorldChangeEntry in world_changes:
		if entry.action == WorldChangeEntry.ActionType.CONVERT_DRONES and bisa_jadi_baik:
			# Drone tidak urus kamera. WorldChangeMarker di scene yang urus sorot area.
			# Tapi kita delay konversi agar sinkron dengan kamera (pan + 0.3 detik jeda).
			# Total delay ≈ DURATION_PAN_TO + DELAY_BEFORE_EFFECT dari CameraDirector
			var delay := CameraDirector.DURATION_PAN_TO + CameraDirector.DELAY_BEFORE_EFFECT
			await get_tree().create_timer(delay).timeout
			if not is_inside_tree(): return
			_become_friendly()

func _become_friendly():
	if is_friendly:
		return
	is_friendly = true
	update_animation()
	if sfx_konversi != null:
		sfx_konversi.play()
	if hurt_box_collision:
		hurt_box_collision.set_deferred("disabled", true)
	set_collision_mask_value(2, false)
	set_collision_layer_value(3, false)
	set_collision_layer_value(1, true)

func update_animation():
	if is_friendly:
		sprite.play("walk_friendly")
	else:
		sprite.play("walk_evil")

func _on_hurt_box_body_entered(body):
	if not is_friendly and body.is_in_group("player"):
		body.take_damage(1, global_position)

func _physics_process(_delta):
	velocity.x = arah * kecepatan
	move_and_slide()
	if global_position.x >= batas_kanan:
		arah = -1
		sprite.flip_h = true
	elif global_position.x <= batas_kiri:
		arah = 1
		sprite.flip_h = false
