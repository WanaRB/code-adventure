extends Node

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                    KONFIGURASI TAMPILAN WIN SCREEN                         ║
# ║  Ubah nilai di sini untuk atur posisi, warna, dan ukuran font              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

## Lebar panel utama (pixel)
const CFG_PANEL_W       := 560.0
## Tinggi panel utama (pixel). Naikkan jika konten terpotong.
const CFG_PANEL_H       := 440.0
## Jarak antar baris di dalam panel
const CFG_ROW_GAP       := 10
## Ukuran font judul (SELAMAT!)
const CFG_SIZE_JUDUL    := 32
## Ukuran font subjudul (Hasil Level X)
const CFG_SIZE_SUBJUDUL := 18
## Ukuran font baris detail poin
const CFG_SIZE_DETAIL   := 20
## Ukuran font baris total poin
const CFG_SIZE_TOTAL    := 22
## Ukuran font tombol
const CFG_SIZE_BTN      := 16
## Tinggi tombol (pixel)
const CFG_BTN_H         := 46.0
## Margin kiri & kanan isi panel (pixel)
const CFG_MARGIN_H      := 40.0
## Margin atas isi panel (pixel)
const CFG_MARGIN_TOP    := 32.0

# ─── Warna — ganti string hex sesuai selera ───────────────────────────────────
const C_BG_DIM    := Color(0, 0, 0, 0.75)         ## Warna layar gelap di belakang panel
const C_PANEL     := Color("#1e1e2e")              ## Warna latar panel
const C_BORDER    := Color("#f9e2af")              ## Warna border panel
const C_JUDUL     := Color("#f9e2af")              ## Warna teks SELAMAT!
const C_SUBJUDUL  := Color("#89b4fa")              ## Warna teks "Hasil Level X"
const C_POSITIF   := Color("#a6e3a1")              ## Warna poin positif (benar, bonus, item)
const C_NEGATIF   := Color("#f38ba8")              ## Warna poin negatif (kesalahan)
const C_NETRAL    := Color("#585b70")              ## Warna kesalahan = 0
const C_TOTAL     := Color("#f9e2af")              ## Warna baris Total
const C_SEP       := Color("#313244")              ## Warna garis pemisah
const C_BTN_MENU  := Color("#585b70")              ## Warna border tombol Main Menu
const C_BTN_ULANGI:= Color("#89b4fa")              ## Warna border tombol Ulangi
const C_BTN_LANJUT:= Color("#a6e3a1")              ## Warna border tombol Level Selanjutnya

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	var scene_path := get_tree().current_scene.scene_file_path
	if "menang" not in scene_path:
		return   # Script ini ada di LoseScreen juga — keluar jika bukan winscreen

	_build_ui()

func _build_ui():
	var root := get_tree().current_scene

	# ── Latar belakang gelap ──
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = C_BG_DIM
	root.add_child(dim)

	# ── Panel tengah ──
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(CFG_PANEL_W, CFG_PANEL_H)
	var ps := StyleBoxFlat.new()
	ps.bg_color = C_PANEL
	ps.set_corner_radius_all(14)
	ps.set_border_width_all(2)
	ps.border_color = C_BORDER
	ps.shadow_color = Color(0, 0, 0, 0.5)
	ps.shadow_size = 20
	# Margin diatur oleh MarginContainer di bawah, bukan StyleBox
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
	var level: int = _get_level()
	var result: Dictionary = SaveManager.get_level_result(level)

	var correct:  int = int(result.get("correct",  0))
	var bonus:    int = int(result.get("bonus",    0))
	var item_pts: int = int(result.get("item_pts", 0))
	var wrong:    int = int(result.get("wrong",    0))
	var penalty:  int = wrong * 10
	var total:    int = max(0, correct * 100 + bonus + item_pts - penalty)

	_lbl(vbox, "✦  SELAMAT!  ✦",          CFG_SIZE_JUDUL,    C_JUDUL,    true)
	_lbl(vbox, "Hasil Level %d" % level,   CFG_SIZE_SUBJUDUL, C_SUBJUDUL, false)
	_sep(vbox)
	_row(vbox, "Soal benar  (%d × 100)" % correct, "+%d" % (correct * 100), C_POSITIF)
	_row(vbox, "Bonus kecepatan",                   "+%d" % bonus,           C_POSITIF)
	_row(vbox, "Item",                              "+%d" % item_pts,        C_POSITIF)
	_row(vbox, "Kesalahan  (%d × -10)" % wrong,     "-%d" % penalty,
		C_NETRAL if penalty == 0 else C_NEGATIF)
	_sep(vbox)
	_row(vbox, "Total", "%d poin" % total, C_TOTAL, CFG_SIZE_TOTAL)

	# Spacer fleksibel agar tombol terdorong ke bawah
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# ── Baris tombol ──
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var btn_menu := _btn("Main Menu", C_BTN_MENU)
	btn_menu.pressed.connect(_ke_menu)
	btn_row.add_child(btn_menu)

	var btn_ulangi := _btn("↺  Ulangi", C_BTN_ULANGI)
	btn_ulangi.pressed.connect(_ulangi)
	btn_row.add_child(btn_ulangi)

	if level < 3:
		var btn_lanjut := _btn("▶  Lanjut", C_BTN_LANJUT)
		btn_lanjut.pressed.connect(_ke_level_selanjutnya)
		btn_row.add_child(btn_lanjut)

# ─── Navigasi ─────────────────────────────────────────────────────────────────
func _ke_menu():
	get_tree().change_scene_to_file("res://scenes/Tampilan/main_menu.tscn")

func _ulangi():
	var path: String = GameEvents.last_level_path
	get_tree().change_scene_to_file(path if path != "" else "res://scenes/Tampilan/level_1.tscn")

func _ke_level_selanjutnya():
	match _get_level():
		1: get_tree().change_scene_to_file("res://scenes/Tampilan/level_2.tscn")
		2: get_tree().change_scene_to_file("res://scenes/Tampilan/level_3.tscn")

func _get_level() -> int:
	var path: String = GameEvents.last_level_path
	if "level_3" in path: return 3
	if "level_2" in path: return 2
	return 1

# ─── Helper UI ────────────────────────────────────────────────────────────────
func _lbl(parent: Node, text: String, size: int, color: Color, center: bool = false):
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)

func _row(parent: Node, left: String, right: String,
		right_color: Color, right_size: int = CFG_SIZE_DETAIL):
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(hbox)
	var ll := Label.new()
	ll.text = left
	ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ll.add_theme_font_size_override("font_size", CFG_SIZE_DETAIL)
	ll.add_theme_color_override("font_color", Color("#cdd6f4"))
	hbox.add_child(ll)
	var rl := Label.new()
	rl.text = right
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rl.add_theme_font_size_override("font_size", right_size)
	rl.add_theme_color_override("font_color", right_color)
	hbox.add_child(rl)

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
