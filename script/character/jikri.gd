extends CharacterBody2D

# Konfigurasi Pergerakan
const SPEED = 400.0
const JUMP_VELOCITY = -500.0
@export var knockback_power = 800.0

# Referensi Node
@onready var sprite = $AnimatedSprite2D
@onready var sfx_lompat: AudioStreamPlayer = %lompat
@onready var sfx_langkah: AudioStreamPlayer = %lari
const LANGKAH_INTERVAL := 0.35
var _langkah_timer: float = 0.0

# ─── Skill Double Jump ──────────────────────────────────────────────────────────
var jump_count: int = 2
var _jump_used: int = 0

# ─── Skill: Anchor Point ─────────────────────────────────────────────────────
@export var anchor_cooldown: float = 5.0
var has_anchor: bool = false
var _anchor_timer: float = 0.0
var _anchor_active: bool = false
var _anchor_position: Vector2 = Vector2.ZERO
var _anchor_ghost: Node2D = null

# ─── Skill: Scout Drone ──────────────────────────────────────────────────────
@export var scout_drone_scene: PackedScene
var has_scout: bool = true
var _scout_drone: Node2D = null
var _kunci_input_timer: float = 0.0
var equipped_skill: String = ""

# Status Karakter
var is_hurt = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# LOGIKA BARU: Jika timer aktif, paksa karakter mengerem
	if _kunci_input_timer > 0.0:
		_kunci_input_timer -= delta
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	elif not is_hurt:
		if _scout_drone == null:
			handle_movement()
			_handle_skill_input()
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, 10.0)
		
	update_animation()
	if _anchor_timer > 0.0:
		_anchor_timer -= delta
	move_and_slide()
	
func handle_movement():
	if is_on_floor():
		_jump_used = 0

	if Input.is_action_just_pressed("lompat") and _jump_used < jump_count:
		sfx_lompat.play()
		velocity.y = JUMP_VELOCITY
		_jump_used += 1
		if _jump_used > 1:
			sprite.play("double_jump")

	var direction := Input.get_axis("kiri", "kanan")
	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	# Suara langkah kaki
	var sedang_jalan := is_on_floor() and direction != 0
	
	if sedang_jalan:
		_langkah_timer -= get_physics_process_delta_time()
		if _langkah_timer <= 0.0:
			_langkah_timer = LANGKAH_INTERVAL
			sfx_langkah.play()
	else:
		_langkah_timer = 0.0
func update_animation():
	# Prioritas 1: Kena Hit
	if is_hurt:
		sprite.play("hit")
		return
		
	# Prioritas 1.5: Double Jump (override jump/fall biasa)
	if sprite.animation == "double_jump" and sprite.is_playing() and not is_on_floor() and _jump_used > 1:
		return

	# Prioritas 2: Di Udara (Jump vs Fall)
	if not is_on_floor():
		if velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("fall")
		return # Keluar agar tidak tertimpa animasi walk/idle saat di udara

	# Prioritas 3: Berjalan
	if velocity.x != 0:
		sprite.play("walk")
	
	# Prioritas 4: Diam (Idle)
	else:
		sprite.play("idle")

func take_damage(amount: int, source_position: Vector2):
	if is_hurt: return 
	is_hurt = true
	
	velocity = Vector2.ZERO
	GameEvents.player_hit.emit(amount)
	
	if not is_inside_tree(): return 

	# Logika Knockback (Bias -350 sesuai koordinat map)
	var arah_horisontal = 0
	var diff_x = global_position.x - source_position.x
	
	if diff_x > -350: 
		arah_horisontal = 1  
	else:
		arah_horisontal = -1 

	var knockback_vector = Vector2(arah_horisontal * 2.0, -1.0).normalized()
	velocity = knockback_vector * knockback_power
	
	var tree = get_tree()
	if tree:
		await tree.create_timer(0.4).timeout
		if is_inside_tree():
			is_hurt = false
			
func _handle_skill_input() -> void:
	if Input.is_action_just_pressed("skill_use"):
		if has_anchor and _anchor_timer <= 0.0:
			if not _anchor_active:
				_set_anchor()
			else:
				_tarik_anchor()
		elif has_scout and _scout_drone == null:
			_mulai_scout()

func _set_anchor() -> void:
	_anchor_active = true
	_anchor_position = global_position
	
	_anchor_ghost = sprite.duplicate()
	_anchor_ghost.modulate = Color(1, 1, 1, 0.35)
	
	_anchor_ghost.global_scale = sprite.global_scale
	
	get_parent().add_child(_anchor_ghost)
	_anchor_ghost.global_position = _anchor_position
	_anchor_ghost.pause()

func _tarik_anchor() -> void:
	global_position = _anchor_position
	velocity = Vector2.ZERO
	_anchor_active = false
	_anchor_timer = anchor_cooldown
	if _anchor_ghost:
		_anchor_ghost.queue_free()
		_anchor_ghost = null

func _mulai_scout() -> void:
	if scout_drone_scene == null:
		push_warning("Jikri: scout_drone_scene belum diisi di Inspector")
		return
	_scout_drone = scout_drone_scene.instantiate()
	get_parent().add_child(_scout_drone)
	_scout_drone.global_position = global_position + Vector2(0, -60)
	_scout_drone.player = self
	_scout_drone.add_collision_exception_with(self)
	var mc := get_tree().get_first_node_in_group("mobile_controls")
	if mc and mc.has_method("masuk_mode_drone"):
		mc.masuk_mode_drone()

func _akhiri_scout() -> void:
	if _scout_drone:
		_scout_drone.queue_free()
		_scout_drone = null
	var main_cam := get_tree().get_first_node_in_group("main_camera")
	if main_cam and main_cam.has_method("make_current"):
		main_cam.make_current()
	var mc := get_tree().get_first_node_in_group("mobile_controls")
	if mc and mc.has_method("keluar_mode_drone"):
		mc.keluar_mode_drone()
	_kunci_input_timer = 0.6

func _equip_skill(skill_id: String) -> void:
	jump_count = 1
	has_anchor = false
	has_scout = false
	equipped_skill = skill_id
	if _anchor_active:
		if _anchor_ghost:
			_anchor_ghost.queue_free()
			_anchor_ghost = null
		_anchor_active = false
	if _scout_drone:
		_akhiri_scout()
	match skill_id:
		"double_jump": jump_count = 2
		"anchor": has_anchor = true
		"scout": has_scout = true

func is_scouting() -> bool:
	return _scout_drone != null
