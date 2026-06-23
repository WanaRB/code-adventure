extends StaticBody2D

@export var laser_id: int = 1
@export var sfx_matikan: AudioStreamPlayer

# Mendaftarkan kelima set node sesuai dengan hierarki gambar Anda
@onready var semua_visual: Array[ColorRect] = [$LaserVisual, $LaserVisual2, $LaserVisual3, $LaserVisual4, $LaserVisual5]
@onready var semua_collision: Array[CollisionShape2D] = [$CollisionShape2D, $CollisionShape2D2, $CollisionShape2D3, $CollisionShape2D4, $CollisionShape2D5]
@onready var semua_hurtbox: Array[Area2D] = [$HurtBox, $HurtBox2, $HurtBox3, $HurtBox4, $HurtBox5]

var _pulse_tween: Tween

func _ready() -> void:
	GameEvents.lever_pulled.connect(_on_lever_pulled)
	
	# 1. Hubungkan sinyal tabrakan untuk KELIMA laser
	for hb in semua_hurtbox:
		hb.body_entered.connect(_on_hurt_box_body_entered)
	
	# 2. Buat kelima visual berdenyut secara BERSAMAAN (Parallel)
	_pulse_tween = create_tween().set_loops()
	
	# Fase A: Menuju redup bersamaan
	for visual in semua_visual:
		_pulse_tween.parallel().tween_property(visual, "modulate:a", 0.6, 0.5)
		
	_pulse_tween.chain() # Tunggu hingga fase redup selesai
	
	# Fase B: Menuju terang bersamaan
	for visual in semua_visual:
		_pulse_tween.parallel().tween_property(visual, "modulate:a", 1.0, 0.5)

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
		
	# 3. Matikan sifat fisik untuk KELIMA laser
	for col in semua_collision:
		col.set_deferred("disabled", true)
	for hb in semua_hurtbox:
		hb.set_deferred("monitoring", false)
	
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
		
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	
	# 4. Pudarkan KELIMA laser secara BERSAMAAN saat dimatikan
	for visual in semua_visual:
		tw.parallel().tween_property(visual, "modulate:a", 0.0, 0.4)
	
	# Hapus node setelah animasi pudar selesai
	tw.chain().tween_callback(queue_free)
