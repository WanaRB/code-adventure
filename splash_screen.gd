extends Control

# ─── KONFIGURASI ──────────────────────────────────────────────────────────────
## Warna latar splash screen — samakan dengan warna background main menu
@export var warna_bg: Color = Color("#1a1a2e")

## Teks yang ditampilkan di tengah layar
@export var teks: String = "Klik untuk Mulai"

## Ukuran teks
@export var ukuran_teks: int = 48

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = warna_bg
	add_child(bg)

	# Teks tengah
	var label := Label.new()
	label.text = teks
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", ukuran_teks)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	add_child(label)

	# Animasi kedip pada teks agar terlihat interaktif
	var tween := create_tween().set_loops()
	tween.tween_property(label, "modulate:a", 0.2, 0.9)
	tween.tween_property(label, "modulate:a", 1.0, 0.9)

func _input(event: InputEvent) -> void:
	# Tunggu klik mouse atau tap layar
	var is_interaksi : bool = (
		event is InputEventMouseButton and event.pressed or
		event is InputEventScreenTouch and event.pressed
	)
	if not is_interaksi:
		return
	# Pindah ke main menu — musik akan diplay di sana karena interaksi sudah terjadi
	get_tree().change_scene_to_file("res://scenes/UI/main_menu.tscn")
