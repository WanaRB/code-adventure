extends CharacterBody2D

# Konfigurasi Pergerakan
const SPEED = 400.0
const JUMP_VELOCITY = -500.0
@export var knockback_power = 800.0

# Status Karakter
var is_hurt = false

func _physics_process(delta: float) -> void:
	# 1. Logika Gravitasi (Selalu Berjalan)
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Logika Pergerakan & Input (Hanya jika TIDAK sedang terkena serangan)
	if not is_hurt:
		handle_movement()
	else:
		# Jika sedang hurt, biarkan gaya dorong melambat perlahan (Friction)
		velocity.x = move_toward(velocity.x, 0, 5.0)

	# 3. Eksekusi Gerakan Fisika
	move_and_slide()

func handle_movement():
	# Lompat
	if Input.is_action_just_pressed("lompat") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Gerak Kiri/Kanan
	var direction := Input.get_axis("kiri", "kanan")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func take_damage(amount: int, source_position: Vector2):
	if is_hurt: return 
	is_hurt = true
	
	velocity = Vector2.ZERO # Reset momentum
	GameEvents.player_hit.emit(amount)
	
	if not is_inside_tree(): return 

	# LOGIKA DETEKSI SISI (RELATIF)
	var arah_horisontal = 0
	
	# Gunakan perbandingan posisi dengan toleransi offset
	# Karena debug kamu menunjukkan angka -262 (kanan) dan -440 (kiri),
	# titik tengahnya adalah sekitar -350.
	var diff_x = global_position.x - source_position.x
	
	# Kita gunakan logika: jika diff_x lebih besar dari rata-rata bias, berarti di kanan
	if diff_x > -350: 
		arah_horisontal = 1  # Terpental ke kanan
	else:
		arah_horisontal = -1 # Terpental ke kiri

	# Eksekusi Knockback dengan rasio X lebih besar agar jauh menyamping
	var knockback_vector = Vector2(arah_horisontal * 2.0, -1.0).normalized()
	velocity = knockback_vector * knockback_power
	
	modulate = Color(2.29, 0.25, 0.0, 1.0) 
	
	var tree = get_tree()
	if tree:
		await tree.create_timer(0.4).timeout
		if is_inside_tree():
			modulate = Color(1, 1, 1)
			is_hurt = false
