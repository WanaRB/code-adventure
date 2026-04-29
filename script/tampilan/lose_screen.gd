extends Control

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                   KONFIGURASI TAMPILAN LOSE SCREEN                         ║
# ║  Ubah nilai di sini untuk atur posisi, warna, dan ukuran font              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

## Lebar panel (pixel)
const CFG_PANEL_W     := 460.0
## Tinggi panel (pixel). Naikkan jika konten terpotong.
const CFG_PANEL_H     := 320.0
## Jarak antar baris
const CFG_ROW_GAP     := 12
## Ukuran font judul (GAME OVER)
const CFG_SIZE_JUDUL  := 32
## Ukuran font poin
const CFG_SIZE_POIN   := 24
## Ukuran font sub-keterangan
const CFG_SIZE_HINT   := 13
## Ukuran font tombol
const CFG_SIZE_BTN    := 18
## Tinggi tombol (pixel)
const CFG_BTN_H       := 44.0
## Margin kiri & kanan isi panel
const CFG_MARGIN_H    := 36.0
## Margin atas isi panel
const CFG_MARGIN_TOP  := 28.0

# ─── Warna ────────────────────────────────────────────────────────────────────
const C_BG_DIM   := Color(0, 0, 0, 0.75)   ## Warna latar gelap
const C_PANEL    := Color("#1e1e2e")        ## Warna panel
const C_BORDER   := Color("#f38ba8")        ## Warna border panel (merah muda)
const C_JUDUL    := Color("#f38ba8")        ## Warna teks GAME OVER
const C_POIN     := Color("#f9e2af")        ## Warna angka poin
const C_HINT     := Color("#585b70")        ## Warna teks keterangan kecil
const C_SEP      := Color("#313244")        ## Warna garis pemisah
const C_BTN_MENU := Color("#585b70")        ## Warna border tombol Menu
const C_BTN_RETRY:= Color("#f38ba8")        ## Warna border tombol Coba Lagi

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_ui()

func _build_ui():
	# ── Latar gelap ──
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = C_BG_DIM
	add_child(dim)

	# ── Panel tengah ──
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(CFG_PANEL_W, CFG_PANEL_H)
	var ps := StyleBoxFlat.new()
	ps.bg_color = C_PANEL
	ps.set_corner_radius_all(14)
	ps.set_border_width_all(2)
	ps.border_color = C_BORDER
	ps.shadow_color = Color(0, 0, 0, 0.5)
	ps.shadow_size = 20
	ps.content_margin_left   = 0
	ps.content_margin_right  = 0
	ps.content_margin_top    = 0
	ps.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)

	# ── MarginContainer sebagai padding dalam panel ──
	var margin_c := MarginContainer.new()
	margin_c.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_c.add_theme_constant_override("margin_left",   CFG_MARGIN_H)
	margin_c.add_theme_constant_override("margin_right",  CFG_MARGIN_H)
	margin_c.add_theme_constant_override("margin_top",    CFG_MARGIN_TOP)
	margin_c.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin_c)

	# ── VBox utama ──
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", CFG_ROW_GAP)
	margin_c.add_child(vbox)

	# ── Konten ──
	var net: int = GameEvents.last_session_net

	_lbl(vbox, "✖  GAME OVER  ✖", CFG_SIZE_JUDUL, C_JUDUL)
	_sep(vbox)
	_lbl(vbox, "%d poin" % net, CFG_SIZE_POIN, C_POIN)
	_sep(vbox)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# ── Baris tombol ──
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var btn_menu := _btn("Main Menu", C_BTN_MENU)
	btn_menu.pressed.connect(_ke_menu)
	btn_row.add_child(btn_menu)

	var btn_retry := _btn("↺  Coba Lagi", C_BTN_RETRY)
	btn_retry.pressed.connect(_retry)
	btn_row.add_child(btn_retry)

# ─── Navigasi ─────────────────────────────────────────────────────────────────
func _ke_menu():
	get_tree().change_scene_to_file("res://scenes/UI/main_menu.tscn")

func _retry():
	var path: String = GameEvents.last_level_path
	get_tree().change_scene_to_file(path if path != "" else "res://scenes/Level/level_1.tscn")

# ─── Helper UI ────────────────────────────────────────────────────────────────
func _lbl(parent: Node, text: String, size: int, color: Color):
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)

func _sep(parent: Node):
	var r := ColorRect.new()
	r.custom_minimum_size = Vector2(0, 1)
	r.color = C_SEP
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(r)

func _btn(text: String, border: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, CFG_BTN_H)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", CFG_SIZE_BTN)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	var s := StyleBoxFlat.new()
	s.bg_color = Color(border.r, border.g, border.b, 0.15)
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(7)
	btn.add_theme_stylebox_override("normal", s)
	var sh: StyleBoxFlat = s.duplicate()
	sh.bg_color = Color(border.r, border.g, border.b, 0.35)
	btn.add_theme_stylebox_override("hover", sh)
	return btn
