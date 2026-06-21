extends CharacterBody2D

@export var move_speed: float = 300.0
@export var max_distance: float = 600.0

@onready var cam: Camera2D = %DroneCam
@onready var noise_rect: ColorRect = %NoiseRect


var player: Node2D = null

func _ready() -> void:
	add_to_group("scout_drone")
	cam.make_current()
	CameraDirector.register_camera(cam)
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(6, true)
	set_collision_mask_value(1, true)

func _physics_process(delta: float) -> void:
	if player == null:
		queue_free()
		return

	if Input.is_action_just_pressed("skill_use"):
		player.call("_akhiri_scout")
		return

	var dir := Vector2.ZERO
	dir.x = Input.get_axis("drone_left", "drone_right")
	dir.y = Input.get_axis("drone_up", "drone_down")
	velocity = dir.normalized() * move_speed
	move_and_slide()

	var dist := global_position.distance_to(player.global_position)
	var ratio: float = clamp(dist / max_distance, 0.0, 1.0)
	ratio = ratio * ratio  # makin terasa kuat saat mendekati batas
	if noise_rect and noise_rect.material is ShaderMaterial:
		noise_rect.material.set_shader_parameter("noise_amount", ratio)

	if dist >= max_distance:
		player.call("_akhiri_scout")
