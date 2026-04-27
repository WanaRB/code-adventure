extends Camera2D

# ─── KONFIGURASI KAMERA ───────────────────────────────────────────────────────

## Zoom kamera. Angka LEBIH BESAR = lebih dekat ke player.
## 1.0 = normal, 1.5 = 50% lebih dekat, 2.0 = 2x lebih dekat.
## Ubah nilai ini untuk mengatur seberapa dekat kamera ke player.
@export var zoom_level: float = 1.6

## Batas kiri kamera (pixel). Player tidak akan melihat area di kiri nilai ini.
## Set ke 0 untuk batas kiri map.
@export var limit_kiri: int   = 0

## Batas kanan kamera (pixel). Ukur lebar map di editor lalu isi di sini.
@export var limit_kanan: int  = 3840

## Batas atas kamera (pixel). Set ke 0 atau nilai negatif jika map tinggi.
@export var limit_atas: int   = -200

## Batas bawah kamera (pixel). Ukur tinggi map di editor lalu isi di sini.
@export var limit_bawah: int  = 1080

func _ready() -> void:
	CameraDirector.register_camera(self)

	# Terapkan zoom
	zoom = Vector2(zoom_level, zoom_level)

	# Terapkan limit agar kamera tidak keluar melewati batas map
	limit_left   = limit_kiri
	limit_right  = limit_kanan
	limit_top    = limit_atas
	limit_bottom = limit_bawah
