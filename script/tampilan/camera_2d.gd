extends Camera2D

# ─── KONFIGURASI KAMERA ────────────────────────────────────────────────────────

## Zoom di Laptop/PC (angka lebih besar = lebih dekat ke player)
@export var zoom_desktop: float = 1.6

## Zoom di Mobile (HP/tablet). Dibuat lebih besar dari desktop
## karena layar HP lebih kecil sehingga game terlihat lebih jauh.
@export var zoom_mobile:  float = 2.2

## Batas kiri kamera — set ke 0 untuk tepi kiri map
@export var limit_kiri:   int   = 0
## Batas kanan kamera — ukur lebar map (pixel) di editor
@export var limit_kanan:  int   = 3512
## Batas atas kamera
@export var limit_atas:   int   = -300
## Batas bawah kamera — ukur tinggi map (pixel) di editor
@export var limit_bawah:  int   = 1080

func _ready() -> void:
	CameraDirector.register_camera(self)

	# Pilih zoom berdasarkan platform
	var is_mobile := OS.has_feature("web_android") or OS.has_feature("web_ios")
	var z := zoom_mobile if is_mobile else zoom_desktop
	zoom = Vector2(z, z)

	limit_left   = limit_kiri
	limit_right  = limit_kanan
	limit_top    = limit_atas
	limit_bottom = limit_bawah
