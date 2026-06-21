extends StaticBody2D

@export var laser_id: int = 1
@export var sfx_matikan: AudioStreamPlayer

@onready var laser_visual: ColorRect = $LaserVisual
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hurt_box: Area2D = $HurtBox

# Tambahkan variabel untuk menyimpan referensi tween pulse
var _pulse_tween: Tween

func _ready() -> void:
	GameEvents.lever_pulled.connect(_on_lever_pulled)
	hurt_box.body_entered.connect(_on_hurt_box_body_entered)
	
	# Simpan ke variabel agar bisa dimatikan nanti
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(laser_visual, "modulate:a", 0.6, 0.5)
	_pulse_tween.tween_property(laser_visual, "modulate:a", 1.0, 0.5)

func _on_hurt_box_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(1, global_position)

func _on_lever_pulled(id: int) -> void:
	if id != laser_id:
		return
	CameraDirector.queue_cinematic(
		global_position,
		_matikan_laser,
		Callable(),
		0.6
	)

func _matikan_laser() -> void:
	if sfx_matikan != null:
		sfx_matikan.play()
	collision.set_deferred("disabled", true)
	hurt_box.set_deferred("monitoring", false)
	
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
		
	var tw := create_tween()
	# TAMBAHKAN BARIS INI: Agar tween tetap jalan meski game di-pause CameraDirector
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	
	tw.tween_property(laser_visual, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)
