extends Area2D

@export var damage_amount: int = 3

func _ready():
	# Hubungkan sinyal deteksi
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Memanggil fungsi damage pada Jikri
		# Mengirim global_position agar Jikri terpental menjauh dari pusat duri
		body.take_damage(damage_amount, global_position)
