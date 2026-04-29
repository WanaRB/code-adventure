extends Control

var _confirm_dialog: Panel = null
var _is_showing_confirm := false
var _is_dark_mode := false

# Referensi node yang perlu diubah warna
@onready var _panel: Panel = $Panel
@onready var _vbox: VBoxContainer = $VBoxContainer

func _ready() -> void:
	_add_theme_toggle()

func _add_theme_toggle() -> void:
	# Tombol toggle Dark/Light mode — pojok kanan atas
	var toggle_btn := Button.new()
	toggle_btn.name = "ThemeToggle"
	toggle_btn.text = "🌙 Dark"
	toggle_btn.flat = true
	toggle_btn.focus_mode = Control.FOCUS_NONE
	toggle_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	toggle_btn.add_theme_font_size_override("font_size", 22)
	toggle_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))

	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0.35)
	s.set_corner_radius_all(10)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	toggle_btn.add_theme_stylebox_override("normal", s)

	var s_hover := StyleBoxFlat.new()
	s_hover.bg_color = Color(0, 0, 0, 0.55)
	s_hover.set_corner_radius_all(10)
	s_hover.content_margin_left = 14
	s_hover.content_margin_right = 14
	s_hover.content_margin_top = 6
	s_hover.content_margin_bottom = 6
	toggle_btn.add_theme_stylebox_override("hover", s_hover)
	toggle_btn.add_theme_stylebox_override("pressed", s_hover)

	toggle_btn.pressed.connect(func(): _toggle_dark_mode(toggle_btn))

	# Anchor ke pojok kanan atas
	toggle_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	toggle_btn.offset_left = -160
	toggle_btn.offset_top = 16
	toggle_btn.offset_right = -16
	toggle_btn.offset_bottom = 60
	add_child(toggle_btn)

func _toggle_dark_mode(btn: Button) -> void:
	_is_dark_mode = not _is_dark_mode

	if _is_dark_mode:
		btn.text = "☀️ Light"
		# Mode gelap: overlay hitam transparan di atas background
		_apply_dark_mode()
	else:
		btn.text = "🌙 Dark"
		_apply_light_mode()

func _apply_dark_mode() -> void:
	# Cari atau buat dark overlay
	var overlay := get_node_or_null("DarkOverlay")
	if overlay == null:
		overlay = ColorRect.new()
		overlay.name = "DarkOverlay"
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Sisipkan di bawah VBoxContainer agar button masih bisa diklik
		add_child(overlay)
		move_child(overlay, 1)  # Setelah Panel background, sebelum VBox

	overlay.color = Color(0, 0, 0, 0.70)

	# Tombol-tombol: teks tetap hitam tapi background lebih gelap
	_set_buttons_dark(true)

	# Pindahkan ThemeToggle ke atas overlay
	var toggle := get_node_or_null("ThemeToggle")
	if toggle:
		move_child(toggle, get_child_count() - 1)

func _apply_light_mode() -> void:
	var overlay := get_node_or_null("DarkOverlay")
	if overlay:
		overlay.color = Color(0, 0, 0, 0)
	_set_buttons_dark(false)

func _set_buttons_dark(dark: bool) -> void:
	# Modifikasi warna teks tombol supaya kontras dengan mode yang aktif
	var btn_names := ["button_start", "button_level", "button_credit", "button_exit"]
	for btn_name in btn_names:
		var btn := get_node_or_null("VBoxContainer/" + btn_name) as Button
		if btn == null:
			continue
		if dark:
			# Teks putih supaya terlihat di atas gelap
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
			btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
			# Background tombol lebih gelap
			var s := StyleBoxFlat.new()
			s.bg_color = Color("#2c3e50")
			s.set_corner_radius_all(16)
			s.shadow_size = 5
			btn.add_theme_stylebox_override("normal", s)
			var s_h := StyleBoxFlat.new()
			s_h.bg_color = Color("#34495e")
			s_h.set_corner_radius_all(16)
			btn.add_theme_stylebox_override("hover", s_h)
			btn.add_theme_stylebox_override("pressed", s_h)
		else:
			# Reset ke warna asli (hapus override → pakai gaya dari scene)
			btn.remove_theme_color_override("font_color")
			btn.remove_theme_color_override("font_hover_color")
			btn.remove_theme_color_override("font_pressed_color")
			btn.remove_theme_stylebox_override("normal")
			btn.remove_theme_stylebox_override("hover")
			btn.remove_theme_stylebox_override("pressed")

func _on_button_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Level/level_1.tscn")

func _on_button_level_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/level_select.tscn")

func _on_button_credit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/credits.tscn")

func _on_button_exit_pressed() -> void:
	if _is_showing_confirm:
		return
	_show_exit_confirm()

func _show_exit_confirm() -> void:
	_is_showing_confirm = true

	# Dim overlay
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# Panel popup
	var panel := Panel.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color("#ffffff")
	ps.set_corner_radius_all(16)
	ps.shadow_color = Color(0, 0, 0, 0.25)
	ps.shadow_size = 12
	panel.add_theme_stylebox_override("panel", ps)
	panel.custom_minimum_size = Vector2(420, 200)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 28)
	vbox.add_child(margin)

	var inner_vbox := VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 24)
	margin.add_child(inner_vbox)

	var label := Label.new()
	label.text = "Apakah kamu yakin ingin keluar?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#222222"))
	label.add_theme_font_size_override("font_size", 24)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner_vbox.add_child(label)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	inner_vbox.add_child(btn_row)

	# Spacer
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(sp)

	# Tombol YA
	var ya_btn := _make_confirm_btn("Ya, Keluar", Color("#e74c3c"), Color("#c0392b"))
	ya_btn.pressed.connect(func():
		center.queue_free()
		dim.queue_free()
		_is_showing_confirm = false
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.location.href = 'about:blank';")
		else:
			get_tree().quit()
	)
	btn_row.add_child(ya_btn)

	# Tombol TIDAK
	var tidak_btn := _make_confirm_btn("Tidak", Color("#3498db"), Color("#2980b9"))
	tidak_btn.pressed.connect(func():
		center.queue_free()
		dim.queue_free()
		_is_showing_confirm = false
	)
	btn_row.add_child(tidak_btn)

	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(sp2)

	_confirm_dialog = panel

func _make_confirm_btn(label_text: String, bg_normal: Color, bg_hover: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(130, 48)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))

	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = bg_normal
	s_normal.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", s_normal)

	var s_hover := StyleBoxFlat.new()
	s_hover.bg_color = bg_hover
	s_hover.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("hover", s_hover)
	btn.add_theme_stylebox_override("pressed", s_hover)

	return btn
