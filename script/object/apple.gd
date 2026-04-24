extends Area2D

@onready var game_manager: Node = %game_manager
@onready var sfx : AudioStreamPlayer = $AudioStreamPlayer

func _on_body_entered(body: Node2D) -> void:
	if body.name == "jikri":
		# 1. Tambahkan poin terlebih dahulu
		game_manager.add_point()
		
		# 2. Putar suara
		sfx.play()
		
		# 3. Sembunyikan item secara visual agar terlihat sudah diambil
		visible = false
		
		# 4. Matikan deteksi tabrakan agar signal tidak terpancing dua kali
		# Kita gunakan set_deferred karena kita sedang berada di dalam proses fisika
		set_deferred("monitoring", false)
		
		# 5. Tunggu sampai suara selesai diputar
		await sfx.finished
		
		# 6. Baru hapus objek dari memori
		queue_free()
