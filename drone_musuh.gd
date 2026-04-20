extends CharacterBody2D

# Variabel yang bisa diubah di Inspector untuk tiap drone
@export var kecepatan: float = 100.0
@export var jarak_patroli: float = 200.0 # Jarak total bolak-balik

@onready var sprite = $AnimatedSprite2D

var posisi_awal: float
var arah = 1 # 1 untuk kanan, -1 untuk kiri

func _ready():
	# Simpan posisi X awal sebagai titik acuan patroli
	posisi_awal = global_position.x
	# Mulai mainkan animasi jalan
	sprite.play("walk")
	# Menghubungkan sinyal deteksi dari Area2D (HurtBox)
	$HurtBox.body_entered.connect(_on_hurt_box_body_entered)
	
func _on_hurt_box_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(1, global_position)

func _physics_process(delta):
	# Hitung kecepatan gerak horizontal
	velocity.x = arah * kecepatan
	
	# Pindahkan drone
	move_and_slide()
	
	# Logika Bolak-Balik:
	# Jika drone sudah pergi terlalu jauh ke kanan dari posisi awal
	if global_position.x >= posisi_awal + jarak_patroli:
		arah = -1 # Balik badan ke kiri
		sprite.flip_h = true # Balik visual sprite (hadap kiri)
	
	# Jika drone sudah kembali terlalu jauh ke kiri dari posisi awal
	elif global_position.x <= posisi_awal:
		arah = 1 # Balik badan ke kanan
		sprite.flip_h = false # Hadap kanan kembali
