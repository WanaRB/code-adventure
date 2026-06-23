extends CanvasLayer

const CFG_PANEL_WIDTH       := 1200.0
const CFG_FONT_SIZE_CODE    := 26
const CFG_FONT_SIZE_HINT    := 20
const CFG_FONT_SIZE_OPTIONS := 18
const CFG_LINE_HEIGHT       := 42
const CFG_OPTION_BTN_HEIGHT := 56
const CFG_MARGIN_H          := 18
const CFG_SECTION_GAP       := 12
const CFG_PANEL_CORNER      := 10
const CFG_SHADOW_SIZE       := 20

const C_BG        := Color("#1e1e2e")
const C_TITLEBAR  := Color("#11111b")
const C_LINE_HL    := Color("#2a2a3e")
const C_CODE       := Color("#cdd6f4")
const C_LINENO     := Color("#585b70")
const C_HL_WORD    := Color("#f9e2af")
const C_HINT       := Color("#89b4fa")
const C_SEPARATOR  := Color("#313244")
const C_BTN_BG     := Color("#313244")
const C_BTN_BD     := Color("#45475a")
const C_BTN_HVR    := Color("#45475a")
const C_SUCCESS    := Color("#a6e3a1")

const SKILLS := [
	{ "id": "double_jump", "label": "double_jump", "deskripsi": "Lompat dua kali di udara" },
	{ "id": "anchor",      "label": "anchor_point", "deskripsi": "Simpan posisi, tarik balik kapan saja" },
	{ "id": "scout",       "label": "scout_drone",  "deskripsi": "Kirim drone pengintai, lihat area dari jauh" },
]

const SKILL_INFO := {
	"double_jump": {
		"judul": "Double Jump",
		"image": "res://assets/image/HowToPlay/skill/double_jump.png",
		"cara": "Tekan [Lompat] di udara untuk lompat kedua kalinya.",
		"kapan": "Cocok untuk jurang lebar atau platform tinggi yang tidak terjangkau 1 lompatan."
	},
	"anchor": {
		"judul": "Anchor Point",
		"image": "res://assets/image/HowToPlay/skill/anchor.png",
		"cara": "Tekan [R] untuk simpan posisi sekarang. Tekan [R] lagi untuk ditarik balik ke titik itu.",
		"kapan": "Pakai sebelum lompat ke area berbahaya — kalau gagal, tarik balik ke tempat aman."
	},
	"scout": {
		"judul": "Scout Drone",
		"image": "res://assets/image/HowToPlay/skill/scout.png",
		"cara": "Tekan [R] untuk kirim drone. Gerakkan dengan [W][A][S][D]. Tekan [R] lagi untuk kembali.",
		"kapan": "Pakai untuk melihat jalur di depan sebelum maju, terutama area dengan banyak musuh."
	},
}

var _root_vbox_ref: VBoxContainer
var _konten_normal: Array[Control] = []

var _howto_panel: Control = null
var _showing_howto := false

var _option_buttons: Array[Button] = []
var _options_container: Control
var _options_context_label: Label
var _highlight_btn: Button
var _selected_skill_id: String = ""
var _compiling_label: Label
var _compiling_lines: Array[String] = []

func _ready():
	for child in get_children():
		child.queue_free()
	GameEvents.game_over.connect(_force_close)
	_build_ui()

func _build_ui():
	var mono_font := _load_mono_font()

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(CFG_PANEL_WIDTH, 0)
	var ps := StyleBoxFlat.new()
	ps.bg_color = C_BG
	ps.set_corner_radius_all(CFG_PANEL_CORNER)
	ps.shadow_color = Color(0, 0, 0, 0.6)
	ps.shadow_size = CFG_SHADOW_SIZE
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", CFG_SECTION_GAP)
	panel.add_child(root_vbox)

	root_vbox.add_child(_make_title_bar(mono_font))
	root_vbox.add_child(_make_instruction(mono_font))
	root_vbox.add_child(_make_code_block(mono_font))
	root_vbox.add_child(_make_separator())

	_options_container = _make_options_section(mono_font)
	root_vbox.add_child(_options_container)
	_hide_options()

	_compiling_label = Label.new()
	_compiling_label.text = ""
	_compiling_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_compiling_label.add_theme_font_size_override("font_size", 18)
	_compiling_label.add_theme_color_override("font_color", C_SUCCESS)
	if mono_font: _compiling_label.add_theme_font_override("font", mono_font)
	_compiling_label.visible = false
	root_vbox.add_child(_compiling_label)

	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, CFG_SECTION_GAP)
	root_vbox.add_child(pad)
	
	var player := get_tree().get_first_node_in_group("player")
	if player and "equipped_skill" in player:
		var current: String = player.equipped_skill
		if current != "":
			_highlight_btn.text = "\"" + current + "\""
	
	_root_vbox_ref = root_vbox
	for child in root_vbox.get_children():
		_konten_normal.append(child)
	
	var mc := get_tree().get_first_node_in_group("mobile_controls")
	if mc: mc.visible = false

	var hud := get_tree().get_first_node_in_group("hud_manager")
	if hud and hud.has_method("set_hud_visible"):
		hud.set_hud_visible(false)

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
	wrapper.add_child(m)

	var inner := HBoxContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("separation", 7)
	m.add_child(inner)

	for col: Color in [Color("#f38ba8"), Color("#f9e2af"), Color("#a6e3a1")]:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.color = col
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		inner.add_child(dot)

	var sp1 := Control.new()
	sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(sp1)

	var title := Label.new()
	title.text = "  player.gd"
	title.add_theme_color_override("font_color", C_LINENO)
	title.add_theme_font_size_override("font_size", 13)
	if mono_font: title.add_theme_font_override("font", mono_font)
	inner.add_child(title)

	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(sp2)

	var close_btn := Button.new()
	close_btn.text = "x"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	close_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	close_btn.custom_minimum_size = Vector2(40, 36)
	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = C_BG
	s_normal.set_corner_radius_all(5)
	close_btn.add_theme_stylebox_override("normal", s_normal)
	var s_hover := StyleBoxFlat.new()
	s_hover.bg_color = Color("#c0392b")
	s_hover.set_corner_radius_all(5)
	close_btn.add_theme_stylebox_override("hover", s_hover)
	var help_btn := Button.new()
	help_btn.text = "?"
	help_btn.focus_mode = Control.FOCUS_NONE
	help_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	help_btn.add_theme_font_size_override("font_size", 22)
	help_btn.add_theme_color_override("font_color", C_HL_WORD)
	help_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	help_btn.custom_minimum_size = Vector2(40, 36)
	var hs_normal := StyleBoxFlat.new()
	hs_normal.bg_color = C_BG
	hs_normal.set_corner_radius_all(5)
	help_btn.add_theme_stylebox_override("normal", hs_normal)
	var hs_hover := StyleBoxFlat.new()
	hs_hover.bg_color = Color(C_HL_WORD.r, C_HL_WORD.g, C_HL_WORD.b, 0.3)
	hs_hover.set_corner_radius_all(5)
	help_btn.add_theme_stylebox_override("hover", hs_hover)
	help_btn.pressed.connect(_toggle_howto)
	inner.add_child(help_btn)
	close_btn.pressed.connect(_tutup_terminal)
	inner.add_child(close_btn)

	return wrapper

func _make_instruction(mono_font: Font) -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", CFG_MARGIN_H)
	m.add_theme_constant_override("margin_right", CFG_MARGIN_H)
	m.add_theme_constant_override("margin_top", CFG_SECTION_GAP)
	var lbl := Label.new()
	lbl.text = "  Klik sintaks yang di-highlight untuk memilih skill"
	lbl.add_theme_color_override("font_color", C_HINT)
	lbl.add_theme_font_size_override("font_size", CFG_FONT_SIZE_HINT)
	if mono_font: lbl.add_theme_font_override("font", mono_font)
	m.add_child(lbl)
	return m

func _make_code_block(mono_font: Font) -> Control:
	# 1. KOREKSI ARRAY: Menghapus duplikasi baris equip_skill
	var code_lines := [
		"extends CharacterBody2D",
		"",
		"const SPEED = 400.0",
		"const JUMP_VELOCITY = -500.0",
		"",
		"func _skill() -> void:",
		"    load_movement_data()",
		"    ", # Indeks 7: Ruang kosong khusus untuk pendaratan tombol interaktif
		"",
	]
	
	# 2. STRUKTUR WADAH: Gunakan PanelContainer agar menyesuaikan ukuran otomatis
	var code_panel := PanelContainer.new()
	code_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var cps := StyleBoxFlat.new()
	cps.bg_color = Color("#181825")
	# Margin tidak dipakai di StyleBox ini agar garis vertikal bisa menyentuh ujung
	code_panel.add_theme_stylebox_override("panel", cps)

	var outer_hbox := HBoxContainer.new()
	code_panel.add_child(outer_hbox)

	var lineno_col := VBoxContainer.new()
	lineno_col.custom_minimum_size = Vector2(40, 0)
	outer_hbox.add_child(lineno_col)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(1, 0)
	divider.color = C_SEPARATOR
	divider.size_flags_vertical = Control.SIZE_EXPAND_FILL # Garis ini kini akan mengikuti tinggi maksimal HBox
	outer_hbox.add_child(divider)

	var code_col := VBoxContainer.new()
	code_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_hbox.add_child(code_col)

	# 3. PADDING ATAS: Mendorong teks ke bawah agar garis vertikal menjuntai ke atas
	var pad_top_num := Control.new()
	pad_top_num.custom_minimum_size = Vector2(0, 16)
	lineno_col.add_child(pad_top_num)
	
	var pad_top_code := Control.new()
	pad_top_code.custom_minimum_size = Vector2(0, 16)
	code_col.add_child(pad_top_code)

	for i in code_lines.size():
		var nm := MarginContainer.new()
		nm.add_theme_constant_override("margin_right", 10)
		nm.add_theme_constant_override("margin_left", 8)
		nm.custom_minimum_size = Vector2(0, CFG_LINE_HEIGHT)
		var num := Label.new()
		num.text = str(i + 1)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num.add_theme_color_override("font_color", C_LINENO)
		num.add_theme_font_size_override("font_size", CFG_FONT_SIZE_CODE)
		if mono_font: num.add_theme_font_override("font", mono_font)
		nm.add_child(num)
		lineno_col.add_child(nm)

		# 4. KOREKSI INDEKS: Pindahkan tombol interaktif ke indeks 7 (Baris ke-8)
		if i == 7: 
			code_col.add_child(_make_highlight_line(mono_font))
		else:
			var m := MarginContainer.new()
			m.add_theme_constant_override("margin_left", CFG_MARGIN_H)
			m.custom_minimum_size = Vector2(0, CFG_LINE_HEIGHT)
			var lbl := Label.new()
			lbl.text = code_lines[i]
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			
			# Tambahan Kosmetik: Warnai hijau jika baris adalah komentar penjelasan skill
			if code_lines[i].begins_with("#"):
				lbl.add_theme_color_override("font_color", Color("#a6e3a1"))
			else:
				lbl.add_theme_color_override("font_color", C_CODE)
				
			lbl.add_theme_font_size_override("font_size", CFG_FONT_SIZE_CODE)
			if mono_font: lbl.add_theme_font_override("font", mono_font)
			m.add_child(lbl)
			code_col.add_child(m)

	# 5. PADDING BAWAH: Mendorong bagian bawah wadah agar garis vertikal menjuntai melewati angka 12
	var pad_bot_num := Control.new()
	pad_bot_num.custom_minimum_size = Vector2(0, 16)
	lineno_col.add_child(pad_bot_num)
	
	var pad_bot_code := Control.new()
	pad_bot_code.custom_minimum_size = Vector2(0, 16)
	code_col.add_child(pad_bot_code)

	return code_panel

func _make_highlight_line(mono_font: Font) -> Control:
	var row_panel := Panel.new()
	row_panel.custom_minimum_size = Vector2(0, CFG_LINE_HEIGHT)
	var rps := StyleBoxFlat.new()
	rps.bg_color = C_LINE_HL
	row_panel.add_theme_stylebox_override("panel", rps)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	row_panel.add_child(hbox)

	var lpad := Control.new()
	lpad.custom_minimum_size = Vector2(CFG_MARGIN_H, 0)
	hbox.add_child(lpad)

	var prefix := Label.new()
	prefix.text = "    equip_skill("
	prefix.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prefix.add_theme_color_override("font_color", C_CODE)
	prefix.add_theme_font_size_override("font_size", CFG_FONT_SIZE_CODE)
	if mono_font: prefix.add_theme_font_override("font", mono_font)
	hbox.add_child(prefix)

	_highlight_btn = Button.new()
	_highlight_btn.text = "\"none\""
	_highlight_btn.flat = false
	_highlight_btn.focus_mode = Control.FOCUS_NONE
	_highlight_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_highlight_btn.add_theme_font_size_override("font_size", CFG_FONT_SIZE_CODE)
	_highlight_btn.add_theme_color_override("font_color", C_HL_WORD)
	if mono_font: _highlight_btn.add_theme_font_override("font", mono_font)

	var s := StyleBoxFlat.new()
	s.bg_color = Color(C_HL_WORD.r, C_HL_WORD.g, C_HL_WORD.b, 0.15)
	s.border_color = C_HL_WORD
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.content_margin_left = 6
	s.content_margin_right = 6
	_highlight_btn.add_theme_stylebox_override("normal", s)
	var sh := s.duplicate() as StyleBoxFlat
	sh.bg_color = Color(C_HL_WORD.r, C_HL_WORD.g, C_HL_WORD.b, 0.3)
	_highlight_btn.add_theme_stylebox_override("hover", sh)

	_highlight_btn.pressed.connect(_on_highlight_clicked)
	hbox.add_child(_highlight_btn)
	var suffix := Label.new()
	suffix.text = ")"
	suffix.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	suffix.add_theme_color_override("font_color", C_CODE)
	suffix.add_theme_font_size_override("font_size", CFG_FONT_SIZE_CODE)
	if mono_font: suffix.add_theme_font_override("font", mono_font)
	hbox.add_child(suffix)

	return row_panel

func _make_separator() -> Control:
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = C_SEPARATOR
	return sep

func _hide_options() -> void:
	_options_container.modulate = Color(1, 1, 1, 0)
	_options_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for btn in _option_buttons:
		btn.disabled = true

func _show_options() -> void:
	_options_container.modulate = Color(1, 1, 1, 1)
	_options_container.mouse_filter = Control.MOUSE_FILTER_STOP
	for btn in _option_buttons:
		btn.disabled = false

func _make_options_section(mono_font: Font) -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", CFG_MARGIN_H)
	m.add_theme_constant_override("margin_right", CFG_MARGIN_H)
	m.add_theme_constant_override("margin_top", CFG_SECTION_GAP)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	m.add_child(vbox)

	_options_context_label = Label.new()
	_options_context_label.text = "Pilih skill:"
	_options_context_label.add_theme_color_override("font_color", C_HINT)
	_options_context_label.add_theme_font_size_override("font_size", CFG_FONT_SIZE_HINT)
	if mono_font: _options_context_label.add_theme_font_override("font", mono_font)
	vbox.add_child(_options_context_label)

	_option_buttons.clear()
	for skill in SKILLS:
		var opt_btn := Button.new()
		opt_btn.text = skill["label"] + "  —  " + skill["deskripsi"]
		opt_btn.custom_minimum_size = Vector2(0, CFG_OPTION_BTN_HEIGHT)
		opt_btn.focus_mode = Control.FOCUS_NONE
		opt_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		opt_btn.add_theme_font_size_override("font_size", CFG_FONT_SIZE_OPTIONS)
		opt_btn.add_theme_color_override("font_color", C_CODE)
		opt_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		if mono_font: opt_btn.add_theme_font_override("font", mono_font)

		var s := StyleBoxFlat.new()
		s.bg_color = C_BTN_BG
		s.border_color = C_BTN_BD
		s.set_border_width_all(1)
		s.set_corner_radius_all(6)
		opt_btn.add_theme_stylebox_override("normal", s)
		var sh := StyleBoxFlat.new()
		sh.bg_color = C_BTN_HVR
		sh.border_color = C_HINT
		sh.set_border_width_all(1)
		sh.set_corner_radius_all(6)
		opt_btn.add_theme_stylebox_override("hover", sh)

		var captured: String = skill["id"]
		opt_btn.pressed.connect(func(): _on_option_pressed(captured))
		_option_buttons.append(opt_btn)
		vbox.add_child(opt_btn)

	var submit_btn := Button.new()
	submit_btn.text = "▶  Enter"
	submit_btn.custom_minimum_size = Vector2(0, CFG_OPTION_BTN_HEIGHT)
	submit_btn.focus_mode = Control.FOCUS_NONE
	submit_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	submit_btn.add_theme_font_size_override("font_size", CFG_FONT_SIZE_OPTIONS + 4)
	submit_btn.add_theme_color_override("font_color", C_CODE)
	submit_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	if mono_font: submit_btn.add_theme_font_override("font", mono_font)
	var s_submit := StyleBoxFlat.new()
	s_submit.bg_color = Color("#1e3a2f")
	s_submit.border_color = C_SUCCESS
	s_submit.set_border_width_all(1)
	s_submit.set_corner_radius_all(6)
	submit_btn.add_theme_stylebox_override("normal", s_submit)
	submit_btn.pressed.connect(_on_submit_pressed)
	vbox.add_child(submit_btn)

	return m

func _load_mono_font() -> Font:
	const PATH := "res://assets/fonts/JetBrainsMono-VariableFont_wght.ttf"
	if ResourceLoader.exists(PATH):
		return load(PATH) as Font
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Consolas", "monospace"])
	return sf

func _on_highlight_clicked() -> void:
	_show_options()

func _on_option_pressed(skill_id: String) -> void:
	_selected_skill_id = skill_id
	_highlight_btn.text = "\"" + skill_id + "\""
	for i in _option_buttons.size():
		var btn := _option_buttons[i]
		var selected: bool = SKILLS[i]["id"] == skill_id
		var s := StyleBoxFlat.new()
		s.bg_color = C_BTN_HVR if selected else C_BTN_BG
		s.border_color = C_HINT if selected else C_BTN_BD
		s.set_border_width_all(1)
		s.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", s)

func _on_submit_pressed() -> void:
	if _selected_skill_id == "":
		return
	_hide_options()
	_highlight_btn.disabled = true
	_mulai_compiling(_selected_skill_id)

func _mulai_compiling(skill_id: String) -> void:
	_compiling_lines = [
		"   > Fetching %s.dll..." % skill_id,
		"   > Resolving dependencies...",
		"   > Compilation successful. Applied.",
	]
	_compiling_label.visible = true
	for line in _compiling_lines:
		_compiling_label.text = line
		var blink := create_tween()
		blink.tween_property(_compiling_label, "modulate:a", 0.2, 0.08)
		blink.tween_property(_compiling_label, "modulate:a", 1.0, 0.08)
		blink.tween_property(_compiling_label, "modulate:a", 0.2, 0.08)
		blink.tween_property(_compiling_label, "modulate:a", 1.0, 0.08)
		await get_tree().create_timer(1).timeout
		if not is_inside_tree(): return

	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("_equip_skill"):
		player._equip_skill(skill_id)
		GameEvents.skill_unlocked = true
		var mc := get_tree().get_first_node_in_group("mobile_controls")
		if mc and mc.has_method("_tambah_tombol_skill"):
			mc._tambah_tombol_skill()
	
	

	_tutup_terminal()

func _tutup_terminal() -> void:
	GameEvents.skill_terminal_closed.emit()
	get_tree().paused = false
	var mc := get_tree().get_first_node_in_group("mobile_controls")
	if mc: mc.visible = true
	var hud := get_tree().get_first_node_in_group("hud_manager")
	if hud and hud.has_method("set_hud_visible"):
		hud.set_hud_visible(true)
	queue_free()

func _force_close():
	queue_free()

func _toggle_howto() -> void:
	if _showing_howto:
		_tutup_howto()
	else:
		_buka_howto()

func _buka_howto() -> void:
	_showing_howto = true
	for c in _konten_normal:
		c.visible = false

	var mono_font := _load_mono_font()
	var skill_id: String = _selected_skill_id if _selected_skill_id != "" else SKILLS[0]["id"]
	var info: Dictionary = SKILL_INFO.get(skill_id, {})

	_howto_panel = VBoxContainer.new()
	_howto_panel.custom_minimum_size = Vector2(CFG_PANEL_WIDTH, 0)
	_howto_panel.add_theme_constant_override("separation", 10)
	_root_vbox_ref.add_child(_howto_panel)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", CFG_MARGIN_H)
	m.add_theme_constant_override("margin_right", CFG_MARGIN_H)
	m.add_theme_constant_override("margin_top", CFG_SECTION_GAP)
	_howto_panel.add_child(m)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	m.add_child(inner)

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	inner.add_child(tab_row)
	for skill in SKILLS:
		var tab_btn := Button.new()
		tab_btn.text = skill["label"]
		tab_btn.focus_mode = Control.FOCUS_NONE
		tab_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tab_btn.custom_minimum_size = Vector2(0, 44)
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_btn.add_theme_font_size_override("font_size", CFG_FONT_SIZE_OPTIONS + 2)
		if mono_font: tab_btn.add_theme_font_override("font", mono_font)
		var aktif: bool = skill["id"] == skill_id
		var s := StyleBoxFlat.new()
		s.bg_color = C_BTN_HVR if aktif else C_BTN_BG
		s.border_color = C_HINT if aktif else C_BTN_BD
		s.set_border_width_all(1)
		s.set_corner_radius_all(6)
		tab_btn.add_theme_stylebox_override("normal", s)
		tab_btn.add_theme_color_override("font_color", Color(1, 1, 1))
		var captured: String = skill["id"]
		tab_btn.pressed.connect(func():
			_selected_skill_id = captured
			_tutup_howto()
			_buka_howto()
		)
		tab_row.add_child(tab_btn)

	var judul := Label.new()
	judul.text = info.get("judul", "")
	judul.add_theme_font_size_override("font_size", 22)
	judul.add_theme_color_override("font_color", C_HL_WORD)
	if mono_font: judul.add_theme_font_override("font", mono_font)
	inner.add_child(judul)

	var img_path: String = info.get("image", "")
	var img := TextureRect.new()
	img.custom_minimum_size = Vector2(0, 220)
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(img_path):
		img.texture = load(img_path)
	inner.add_child(img)

	var cara_lbl := Label.new()
	cara_lbl.text = "Cara pakai: " + info.get("cara", "")
	cara_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cara_lbl.add_theme_font_size_override("font_size", CFG_FONT_SIZE_HINT)
	cara_lbl.add_theme_color_override("font_color", C_CODE)
	if mono_font: cara_lbl.add_theme_font_override("font", mono_font)
	inner.add_child(cara_lbl)

	var kapan_lbl := Label.new()
	kapan_lbl.text = "Kapan pakai: " + info.get("kapan", "")
	kapan_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kapan_lbl.add_theme_font_size_override("font_size", CFG_FONT_SIZE_HINT)
	kapan_lbl.add_theme_color_override("font_color", C_HINT)
	if mono_font: kapan_lbl.add_theme_font_override("font", mono_font)
	inner.add_child(kapan_lbl)
	
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	inner.add_child(spacer)

	var btn_kembali := Button.new()
	btn_kembali.text = "← Kembali ke Terminal"
	btn_kembali.custom_minimum_size = Vector2(0, CFG_OPTION_BTN_HEIGHT)
	btn_kembali.focus_mode = Control.FOCUS_NONE
	btn_kembali.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_kembali.add_theme_font_size_override("font_size", CFG_FONT_SIZE_OPTIONS)
	btn_kembali.add_theme_color_override("font_color", Color(1, 1, 1))
	if mono_font: btn_kembali.add_theme_font_override("font", mono_font)
	var s_back := StyleBoxFlat.new()
	s_back.bg_color = C_BTN_BG
	s_back.border_color = C_BTN_BD
	s_back.set_border_width_all(1)
	s_back.set_corner_radius_all(6)
	btn_kembali.add_theme_stylebox_override("normal", s_back)
	btn_kembali.pressed.connect(_tutup_howto)
	inner.add_child(btn_kembali)

func _tutup_howto() -> void:
	_showing_howto = false
	if _howto_panel:
		_howto_panel.queue_free()
		_howto_panel = null
	for c in _konten_normal:
		c.visible = true
