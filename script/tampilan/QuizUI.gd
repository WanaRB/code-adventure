extends CanvasLayer

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                    KONFIGURASI TAMPILAN QUIZ                               ║
# ║   Ubah nilai-nilai di bagian ini untuk mengatur tampilan pop-up quiz       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

## Lebar total pop-up quiz (pixel). Naikkan jika kode terpotong.
const CFG_PANEL_WIDTH       := 660.0
## Ukuran font baris kode di dalam editor. Ubah ini untuk perbesar/perkecil kode.
const CFG_FONT_SIZE_CODE    := 14
## Ukuran font teks instruksi dan label. Ubah untuk perbesar/perkecil petunjuk.
const CFG_FONT_SIZE_HINT    := 13
## Ukuran font teks pada tombol pilihan jawaban.
const CFG_FONT_SIZE_OPTIONS := 14
## Tinggi setiap baris kode (pixel). Perbesar jika baris terasa terlalu rapat.
const CFG_LINE_HEIGHT       := 32
## Lebar kolom nomor baris di kiri kode (pixel).
const CFG_LINE_NUMBER_WIDTH := 50
## Tinggi tombol pilihan jawaban (pixel).
const CFG_OPTION_BTN_HEIGHT := 44
## Margin kiri dan kanan konten di dalam panel (pixel).
## Naikkan untuk geser konten ke dalam (menjauhi tepi kiri/kanan).
const CFG_MARGIN_H          := 18
## Jarak vertikal antar bagian UI (pixel).
## Naikkan untuk memberi lebih banyak ruang atas/bawah antar bagian.
const CFG_SECTION_GAP       := 12
## Radius sudut panel (pixel). 0 = kotak, 12+ = sangat membulat.
const CFG_PANEL_CORNER      := 10
## Ukuran bayangan di sekitar panel (pixel). 0 = tidak ada bayangan.
const CFG_SHADOW_SIZE       := 20

# ─── Warna Tema (Code Editor - Terminal Dark) ──────────────────────────────────
const C_BG          := Color("#1e1e2e")
const C_TITLEBAR    := Color("#11111b")
const C_LINE_HL     := Color("#2a2a3e")
const C_CODE        := Color("#cdd6f4")
const C_LINENO      := Color("#585b70")
const C_LINENO_HL   := Color("#cba6f7")
const C_HL_WORD     := Color("#f9e2af")
const C_HINT        := Color("#89b4fa")
const C_SEPARATOR   := Color("#313244")
const C_BTN_BG      := Color("#313244")
const C_BTN_BD      := Color("#45475a")
const C_BTN_HVR     := Color("#45475a")
const C_COMMENT     := Color("#6c7086")
const C_SUCCESS     := Color("#a6e3a1")
const C_WRONG       := Color("#f38ba8")

# ─── State ────────────────────────────────────────────────────────────────────
var _quiz_data: QuizResource = null
var _current_door_id: int = 1          # Tidak lagi dipakai langsung, tapi disimpan
var _action_to_trigger: String = ""    # Tidak lagi dipakai langsung

var _highlight_buttons: Array[Button] = []
var _highlight_correct: Array[bool] = []
var _current_hl_idx: int = -1

# Referensi UI yang perlu diakses setelah build
var _options_container: Control = null
var _options_context_label: Label = null
var _option_buttons: Array[Button] = []

# ─── Sound Effect ─────────────────────────────────────────────────────────────
## AudioStreamPlayer untuk suara jawaban BENAR.
## Tambahkan node AudioStreamPlayer sebagai child QuizUI di scene .tscn,
## lalu drag ke field ini di Inspector.
@export var sfx_benar: AudioStreamPlayer
## AudioStreamPlayer untuk suara jawaban SALAH.
@export var sfx_salah: AudioStreamPlayer

# ─── Setup API (dipanggil dari Laptop.gd) ─────────────────────────────────────
func set_door_id(id: int):
	_current_door_id = id

func setup_quiz(data: QuizResource):
	_quiz_data = data
	_highlight_correct.resize(data.highlights.size())
	_highlight_correct.fill(false)
	_build_ui()

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready():
	# Bersihkan node warisan dari scene template agar tidak konflik
	for child in get_children():
		child.queue_free()

# ─── Builder Utama ────────────────────────────────────────────────────────────
func _build_ui():
	if _quiz_data == null:
		push_error("QuizUI: setup_quiz() belum dipanggil sebelum quiz ditampilkan")
		return

	var mono_font := _load_mono_font()

	# Dim gelap di belakang panel
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# CenterContainer agar panel selalu di tengah layar
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	# Panel utama
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(CFG_PANEL_WIDTH, 400)
	var ps := StyleBoxFlat.new()
	ps.bg_color = C_BG
	ps.set_corner_radius_all(CFG_PANEL_CORNER)
	ps.shadow_color = Color(0, 0, 0, 0.6)
	ps.shadow_size = CFG_SHADOW_SIZE
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)

	# Root VBox
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", CFG_SECTION_GAP)
	panel.add_child(root_vbox)

	root_vbox.add_child(_make_title_bar(mono_font))
	root_vbox.add_child(_make_instruction_bar(mono_font))
	root_vbox.add_child(_make_code_block(mono_font))
	root_vbox.add_child(_make_separator())

	_options_container = _make_options_section(mono_font)
	_options_container.visible = false
	root_vbox.add_child(_options_container)

	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, CFG_SECTION_GAP)
	root_vbox.add_child(pad)

# ─── Title Bar ────────────────────────────────────────────────────────────────
func _make_title_bar(mono_font: Font) -> Control:
	var wrapper := Panel.new()
	var ws := StyleBoxFlat.new()
	ws.bg_color = C_TITLEBAR
	ws.corner_radius_top_left = CFG_PANEL_CORNER
	ws.corner_radius_top_right = CFG_PANEL_CORNER
	wrapper.add_theme_stylebox_override("panel", ws)
	wrapper.custom_minimum_size = Vector2(0, 42)

	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 0)
	m.add_theme_constant_override("margin_bottom", 0)
	wrapper.add_child(m)

	var inner := HBoxContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("separation", 7)
	m.add_child(inner)

	# Titik macOS style
	for col: Color in [C_WRONG, Color("#f9e2af"), C_SUCCESS]:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.color = col
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		inner.add_child(dot)

	var sp1 := Control.new()
	sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(sp1)

	var title := Label.new()
	title.text = "  code_viewer.py"
	title.add_theme_color_override("font_color", C_LINENO)
	title.add_theme_font_override("font", mono_font)
	title.add_theme_font_size_override("font_size", 13)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inner.add_child(title)

	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(sp2)

	# ─── Tombol Exit ───
	# Background: C_BG (hitam kebiru-biruan), teks "✕" putih
	# Hover & pressed: merah, "✕" tetap putih
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.flat = false
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.add_theme_font_override("font", mono_font)
	close_btn.add_theme_font_size_override("font_size", 15)
	close_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	close_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	close_btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
	close_btn.custom_minimum_size = Vector2(32, 28)
	close_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = C_BG
	s_normal.set_corner_radius_all(5)
	close_btn.add_theme_stylebox_override("normal", s_normal)

	var s_hover := StyleBoxFlat.new()
	s_hover.bg_color = Color("#c0392b")
	s_hover.set_corner_radius_all(5)
	close_btn.add_theme_stylebox_override("hover", s_hover)

	var s_pressed := StyleBoxFlat.new()
	s_pressed.bg_color = Color("#922b21")
	s_pressed.set_corner_radius_all(5)
	close_btn.add_theme_stylebox_override("pressed", s_pressed)

	close_btn.pressed.connect(_on_close_pressed)
	inner.add_child(close_btn)

	return wrapper

# ─── Instruksi ────────────────────────────────────────────────────────────────
func _make_instruction_bar(mono_font: Font) -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", CFG_MARGIN_H)
	m.add_theme_constant_override("margin_right", CFG_MARGIN_H)
	m.add_theme_constant_override("margin_top", CFG_SECTION_GAP)
	m.add_theme_constant_override("margin_bottom", CFG_SECTION_GAP / 2)

	var count := _quiz_data.highlights.size()
	var hint_text := "💡  Klik bagian kode yang di-highlight untuk memperbaikinya"
	if count > 1:
		hint_text = "💡  Ada %d bagian kode yang perlu diperbaiki — klik satu per satu" % count

	var lbl := Label.new()
	lbl.text = hint_text
	lbl.add_theme_color_override("font_color", C_HINT)
	lbl.add_theme_font_override("font", mono_font)
	lbl.add_theme_font_size_override("font_size", CFG_FONT_SIZE_HINT)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	m.add_child(lbl)
	return m

# ─── Blok Kode ────────────────────────────────────────────────────────────────
func _make_code_block(mono_font: Font) -> Control:
	var code_panel := Panel.new()
	code_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	code_panel.custom_minimum_size = Vector2(
		0,
		_quiz_data.code_lines.size() * CFG_LINE_HEIGHT + 16
	)

	var cps := StyleBoxFlat.new()
	cps.bg_color = Color("#181825")
	cps.content_margin_top = 8
	cps.content_margin_bottom = 8
	code_panel.add_theme_stylebox_override("panel", cps)

	var outer_hbox := HBoxContainer.new()
	outer_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer_hbox.add_theme_constant_override("separation", 0)
	outer_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	code_panel.add_child(outer_hbox)

	# Kolom nomor baris
	var lineno_col := VBoxContainer.new()
	lineno_col.custom_minimum_size = Vector2(CFG_LINE_NUMBER_WIDTH, 0)
	lineno_col.add_theme_constant_override("separation", 0)
	outer_hbox.add_child(lineno_col)

	# Garis vertikal pemisah
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(1, 0)
	divider.color = C_SEPARATOR
	divider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_hbox.add_child(divider)

	# Kolom kode
	var code_col := VBoxContainer.new()
	code_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_col.add_theme_constant_override("separation", 0)
	outer_hbox.add_child(code_col)

	var hl_map: Dictionary = {}
	for hi: int in range(_quiz_data.highlights.size()):
		var highlight := _quiz_data.highlights[hi]
		hl_map[highlight.line] = hi

	_highlight_buttons.clear()
	_highlight_buttons.resize(_quiz_data.highlights.size())

	for i: int in range(_quiz_data.code_lines.size()):
		var is_hl_row := hl_map.has(i)
		var hl_idx: int = hl_map.get(i, -1)

		var nm := MarginContainer.new()
		nm.add_theme_constant_override("margin_right", 10)
		nm.add_theme_constant_override("margin_left", 8)
		nm.custom_minimum_size = Vector2(0, CFG_LINE_HEIGHT)
		var num := Label.new()
		num.text = str(i + 1)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num.add_theme_color_override("font_color", C_LINENO_HL if is_hl_row else C_LINENO)
		num.add_theme_font_override("font", mono_font)
		num.add_theme_font_size_override("font_size", CFG_FONT_SIZE_CODE)
		nm.add_child(num)
		lineno_col.add_child(nm)

		if is_hl_row:
			var highlight := _quiz_data.highlights[hl_idx]
			var row := _make_highlight_line(_quiz_data.code_lines[i], highlight.word, hl_idx, mono_font)
			code_col.add_child(row)
		else:
			var row := _make_plain_line(_quiz_data.code_lines[i], mono_font)
			code_col.add_child(row)

	return code_panel

# ─── Baris Kode Normal ────────────────────────────────────────────────────────
func _make_plain_line(text: String, mono_font: Font) -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", CFG_MARGIN_H)
	m.add_theme_constant_override("margin_right", CFG_MARGIN_H)
	m.custom_minimum_size = Vector2(0, CFG_LINE_HEIGHT)
	var lbl := Label.new()
	lbl.text = text
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color",
		C_COMMENT if text.strip_edges().begins_with("#") else C_CODE)
	lbl.add_theme_font_override("font", mono_font)
	lbl.add_theme_font_size_override("font_size", CFG_FONT_SIZE_CODE)
	m.add_child(lbl)
	return m

# ─── Baris Kode dengan Highlight ─────────────────────────────────────────────
func _make_highlight_line(text: String, hw: String, hl_idx: int, mono_font: Font) -> Control:
	var row_panel := Panel.new()
	row_panel.custom_minimum_size = Vector2(0, CFG_LINE_HEIGHT)
	var rps := StyleBoxFlat.new()
	rps.bg_color = C_LINE_HL
	row_panel.add_theme_stylebox_override("panel", rps)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 0)
	row_panel.add_child(hbox)

	# Margin kiri
	var lpad := Control.new()
	lpad.custom_minimum_size = Vector2(CFG_MARGIN_H, 0)
	hbox.add_child(lpad)

	var idx := text.find(hw)
	if idx == -1:
		var lbl := Label.new()
		lbl.text = text
		lbl.add_theme_color_override("font_color", C_CODE)
		lbl.add_theme_font_override("font", mono_font)
		lbl.add_theme_font_size_override("font_size", CFG_FONT_SIZE_CODE)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(lbl)
		push_warning("QuizUI: highlight_word '%s' tidak ditemukan di baris '%s'" % [hw, text])
		return row_panel

	# Teks sebelum kata
	if idx > 0:
		hbox.add_child(_code_label(text.substr(0, idx), mono_font))

	# Tombol kata highlight
	var btn := Button.new()
	btn.text = hw
	btn.flat = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_override("font", mono_font)
	btn.add_theme_font_size_override("font_size", CFG_FONT_SIZE_CODE)
	btn.add_theme_color_override("font_color", C_HL_WORD)
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.45, 0.5))

	var _make_hl_style := func(alpha: float, border_col: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(C_HL_WORD.r, C_HL_WORD.g, C_HL_WORD.b, alpha)
		s.border_color = border_col
		s.set_border_width_all(1)
		s.set_corner_radius_all(4)
		s.content_margin_left = 6
		s.content_margin_right = 6
		s.content_margin_top = 1
		s.content_margin_bottom = 1
		return s

	btn.add_theme_stylebox_override("normal",  _make_hl_style.call(0.15, C_HL_WORD))
	btn.add_theme_stylebox_override("hover",   _make_hl_style.call(0.30, C_HL_WORD))
	btn.add_theme_stylebox_override("pressed", _make_hl_style.call(0.45, C_HL_WORD))

	var s_disabled := StyleBoxFlat.new()
	s_disabled.bg_color = Color(0.25, 0.25, 0.3, 0.6)
	s_disabled.set_border_width_all(1)
	s_disabled.border_color = Color(0.35, 0.35, 0.4)
	s_disabled.set_corner_radius_all(4)
	s_disabled.content_margin_left = 6
	s_disabled.content_margin_right = 6
	s_disabled.content_margin_top = 1
	s_disabled.content_margin_bottom = 1
	btn.add_theme_stylebox_override("disabled", s_disabled)

	var captured_idx := hl_idx
	btn.pressed.connect(func(): _on_highlight_clicked(captured_idx))
	_highlight_buttons[hl_idx] = btn
	hbox.add_child(btn)

	# Teks setelah kata
	var after := text.substr(idx + hw.length())
	if after.length() > 0:
		hbox.add_child(_code_label(after, mono_font))

	return row_panel

func _code_label(text: String, mono_font: Font) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", C_CODE)
	lbl.add_theme_font_override("font", mono_font)
	lbl.add_theme_font_size_override("font_size", CFG_FONT_SIZE_CODE)
	return lbl

# ─── Separator ────────────────────────────────────────────────────────────────
func _make_separator() -> Control:
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = C_SEPARATOR
	return sep

# ─── Seksi Pilihan Jawaban ────────────────────────────────────────────────────
func _make_options_section(mono_font: Font) -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", CFG_MARGIN_H)
	m.add_theme_constant_override("margin_right", CFG_MARGIN_H)
	m.add_theme_constant_override("margin_top", CFG_SECTION_GAP)
	m.add_theme_constant_override("margin_bottom", 4)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	m.add_child(vbox)

	# Label konteks: menampilkan kata mana yang sedang diperbaiki
	_options_context_label = Label.new()
	_options_context_label.text = "Pilih nilai yang benar:"
	_options_context_label.add_theme_color_override("font_color", C_HINT)
	_options_context_label.add_theme_font_override("font", mono_font)
	_options_context_label.add_theme_font_size_override("font_size", CFG_FONT_SIZE_HINT)
	vbox.add_child(_options_context_label)

	# Baris tombol pilihan
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_hbox)

	_option_buttons.clear()
	# Buat 3 tombol (teks akan diisi saat highlight diklik)
	for i: int in range(3):
		var opt_btn := Button.new()
		opt_btn.text = ""
		opt_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opt_btn.custom_minimum_size = Vector2(0, CFG_OPTION_BTN_HEIGHT)
		opt_btn.focus_mode = Control.FOCUS_NONE
		opt_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		opt_btn.add_theme_font_override("font", mono_font)
		opt_btn.add_theme_font_size_override("font_size", CFG_FONT_SIZE_OPTIONS)
		opt_btn.add_theme_color_override("font_color", C_CODE)
		opt_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))

		var _make_opt_style := func(bg: Color, border: Color) -> StyleBoxFlat:
			var s := StyleBoxFlat.new()
			s.bg_color = bg
			s.border_color = border
			s.set_border_width_all(1)
			s.set_corner_radius_all(6)
			return s

		opt_btn.add_theme_stylebox_override("normal",  _make_opt_style.call(C_BTN_BG, C_BTN_BD))
		opt_btn.add_theme_stylebox_override("hover",   _make_opt_style.call(C_BTN_HVR, C_HINT))
		opt_btn.add_theme_stylebox_override("pressed", _make_opt_style.call(
			Color(C_HINT.r, C_HINT.g, C_HINT.b, 0.25), C_HINT))

		var captured_i := i
		opt_btn.pressed.connect(func(): _on_option_pressed(captured_i))
		_option_buttons.append(opt_btn)
		btn_hbox.add_child(opt_btn)

	return m

# ─── Helper Font ──────────────────────────────────────────────────────────────
func _load_mono_font() -> Font:
	const PATHS := [
		"res://assets/Fonts/PeaberryBase.ttf",
		"res://assets/Fonts/JetBrainsMono-VariableFont_wght.ttf",
	]
	for p: String in PATHS:
		if ResourceLoader.exists(p):
			return load(p) as Font
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Consolas", "Courier New", "Lucida Console", "monospace"])
	return sf

# ─── Callbacks ────────────────────────────────────────────────────────────────
func _on_highlight_clicked(hl_idx: int):
	if _highlight_correct[hl_idx]:
		return  # Sudah benar, abaikan
	_current_hl_idx = hl_idx

	# Update label konteks
	var hl := _quiz_data.highlights[hl_idx]
	_options_context_label.text = "🔧  Memperbaiki   [ %s ]   — pilih pengganti yang benar:" % hl.word

	# Update teks tombol opsi
	for i: int in range(_option_buttons.size()):
		if i < hl.options.size():
			_option_buttons[i].text = hl.options[i]
			_option_buttons[i].visible = true
		else:
			_option_buttons[i].visible = false

	_options_container.visible = true

func _on_option_pressed(option_idx: int):
	if _current_hl_idx == -1:
		return

	var hl := _quiz_data.highlights[_current_hl_idx]
	var btn := _highlight_buttons[_current_hl_idx]

	if option_idx == hl.correct_index:
		# ── BENAR ──
		_highlight_correct[_current_hl_idx] = true
		btn.text = hl.options[option_idx]
		btn.disabled = true
		btn.add_theme_color_override("font_disabled_color", C_SUCCESS)
		_options_container.visible = false
		_current_hl_idx = -1

		# Mainkan suara benar
		if sfx_benar != null:
			sfx_benar.play()

		# Cek apakah SEMUA highlight sudah dijawab benar
		var semua_benar := true
		for c: bool in _highlight_correct:
			if not c:
				semua_benar = false
				break

		if semua_benar:
			# Tunggu 0.35 detik agar player bisa lihat jawaban benar
			await get_tree().create_timer(0.35).timeout
			if not is_inside_tree():
				return
			# Emit sinyal → pintu/drone/marker mulai bereaksi
			GameEvents.quiz_answered_correct.emit(_quiz_data.world_changes)
			_tutup_kuis()
	else:
		# ── SALAH ──
		btn.text = hl.options[option_idx]
		btn.add_theme_color_override("font_color", C_WRONG)
		if sfx_salah != null:
			sfx_salah.play()
		GameEvents.player_hit.emit(1)

		await get_tree().create_timer(0.4).timeout
		if is_inside_tree():
			# Reset tombol highlight ke kata semula
			btn.text = hl.word
			btn.add_theme_color_override("font_color", C_HL_WORD)

func _on_close_pressed():
	_tutup_kuis()

func _tutup_kuis():
	GameEvents.quiz_closed.emit()
	get_tree().paused = false
	queue_free()
