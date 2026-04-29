extends CharacterBody2D

# Konfigurasi Pergerakan
const SPEED = 400.0
const JUMP_VELOCITY = -500.0
@export var knockback_power = 800.0

# Referensi Node
@onready var sprite = $AnimatedSprite2D
@onready var sfx_langkah: AudioStreamPlayer = %AudioStreamPlayer
const LANGKAH_INTERVAL := 0.35
var _langkah_timer: float = 0.0
var _bisa_double_jump := false

# Status Karakter
var is_hurt = false

func _physics_process(delta: float) -> void:
	# 1. Logika Gravitasi
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Logika Pergerakan & Input
	if not is_hurt:
		handle_movement()
	else:
		# Friction saat terkena knockback
		velocity.x = move_toward(velocity.x, 0, 10.0)

	# 3. Update Animasi
	update_animation()

	# 4. Eksekusi Fisika
	move_and_slide()

func handle_movement():
	if is_on_floor():
		_bisa_double_jump = true  # reset saat menyentuh tanah

	if Input.is_action_just_pressed("lompat"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif _bisa_double_jump:
			velocity.y = JUMP_VELOCITY
			_bisa_double_jump = false
			sprite.play("double_jump")  # ganti nama sesuai animasi di AnimatedSprite2D kamu

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
	if sprite.animation == "double_jump" and sprite.is_playing() and not is_on_floor():
		return  # biarkan animasi double_jump selesai dulu

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
