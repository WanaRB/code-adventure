extends CharacterBody2D

@export var kecepatan: float = 100.0
@export var jarak_patroli: float = 200.0
@export var bisa_jadi_baik: bool = false
@export var mulai_ke_atas: bool = false

## [Opsional] Suara drone berubah jadi baik.
@export var sfx_konversi: AudioStreamPlayer2D

@onready var sprite = $AnimatedSprite2D
@onready var hurt_box_collision = $HurtBox/CollisionShape2D

var batas_atas: float
var batas_bawah: float
var arah: int = 1
var is_friendly := false

func _ready():
	GameEvents.quiz_answered_correct.connect(_on_quiz_solved)

	if mulai_ke_atas:
		arah = -1
		batas_bawah = global_position.y
		batas_atas = global_position.y - jarak_patroli
	else:
		arah = 1
		batas_atas = global_position.y
		batas_bawah = global_position.y + jarak_patroli

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
			var delay := CameraDirector.DURATION_PAN_TO + CameraDirector.DELAY_BEFORE_EFFECT
			await get_tree().create_timer(delay).timeout
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
	velocity.y = arah * kecepatan
	move_and_slide()
	if global_position.y >= batas_bawah:
		arah = -1
	elif global_position.y <= batas_atas:
		arah = 1
