extends CharacterBody2D

# Konfigurasi Pergerakan
const SPEED = 400.0
const JUMP_VELOCITY = -500.0
@export var knockback_power = 800.0

# Referensi Node
@onready var sprite = $AnimatedSprite2D

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
	if Input.is_action_just_pressed("lompat") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("kiri", "kanan")
	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func update_animation():
	# Prioritas 1: Kena Hit
	if is_hurt:
		sprite.play("hit")
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
