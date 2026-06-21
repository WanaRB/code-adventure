extends Area2D

## Cocokkan dengan Laser Id di node LaserDoor.
@export var laser_id: int = 1
## SFX saat lever ditarik.
@export var sfx_tarik: AudioStreamPlayer

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _sudah_ditarik := false
var _drone_di_dekat := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("scout_drone"):
		_drone_di_dekat = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("scout_drone"):
		_drone_di_dekat = false

func _input(event: InputEvent) -> void:
	if _sudah_ditarik:
		return
	if event.is_action_pressed("interact") and _drone_di_dekat:
		_tarik_lever()

func _tarik_lever() -> void:
	_sudah_ditarik = true
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("tertarik"):
		sprite.play("tertarik")
	if sfx_tarik != null:
		sfx_tarik.play()
	GameEvents.lever_pulled.emit(laser_id)
