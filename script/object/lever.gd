extends Area2D

## Cocokkan dengan Laser Id di node LaserDoor.
@export var laser_id: int = 1
## SFX saat lever ditarik.
@export var sfx_tarik: AudioStreamPlayer

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _sudah_ditarik := false
var _drone_di_dekat := false
var _label_interaksi: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_buat_label_interaksi()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("scout_drone"):
		_drone_di_dekat = true
		if _label_interaksi and not _sudah_ditarik:
			_label_interaksi.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("scout_drone"):
		_drone_di_dekat = false
		if _label_interaksi:
			_label_interaksi.visible = false

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
	if _label_interaksi:
		_label_interaksi.visible = false
	GameEvents.lever_pulled.emit(laser_id)

func _buat_label_interaksi() -> void:
	var container := Node2D.new()
	container.position = Vector2(0, -40)
	container.visible = false
	add_child(container)
	_label_interaksi = container
	var label := Label.new()
	label.text = "Tekan [E] untuk interaksi"
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("ffffffff"))
	label.add_theme_color_override("font_outline_color", Color("000000ff"))
	label.add_theme_constant_override("outline_size", 4)
	label.position = Vector2(-90, -10)
	container.add_child(label)
