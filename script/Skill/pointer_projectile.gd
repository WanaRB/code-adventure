extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var max_distance: float = 500.0
var shooter: Node2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _traveled: float = 0.0

func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	for i in range(1, 33):
		collision_mask = 0xFFFFFFFF
	body_entered.connect(_on_body_entered)
	if direction.x < 0:
		scale.x = -1
	sprite.play("default")

func _physics_process(delta: float) -> void:
	var motion := direction * speed * delta
	global_position += motion
	_traveled += motion.length()
	if _traveled >= max_distance:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	print("kena body: ", body.name, " | class: ", body.get_class(), " | layer: ", body.collision_layer if body.has_method("get_collision_layer") else "?")
	if body == shooter:
		return
	if shooter:
		shooter.global_position = global_position
	queue_free()
