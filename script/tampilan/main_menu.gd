extends Control

var _confirm_dialog: Panel = null
var _is_showing_confirm := false
@onready var bgm_menu: AudioStreamPlayer = $BgmMenu
@export var ikon_suara_hidup: Texture2D
@export var ikon_suara_mati: Texture2D

func _ready() -> void:
	_setup_bgm()
	_tambah_tombol_suara()
	
func _setup_bgm() -> void:
	var existing := get_tree().root.get_node_or_null("BgmMenu")
	if existing == null:
		var bgm := AudioStreamPlayer.new()
		bgm.name = "BgmMenu"
		bgm.stream = $BgmMenu.stream
		bgm.volume_db = $BgmMenu.volume_db
		$BgmMenu.queue_free()
		get_tree().root.call_deferred("add_child", bgm)
		# Play setelah masuk tree — aman karena interaksi sudah terjadi di splash screen
		bgm.call_deferred("play")
	else:
		if has_node("BgmMenu"):
			$BgmMenu.queue_free()
		if GameEvents.musik_menu_hidup and not existing.playing:
			existing.play()
		elif not GameEvents.musik_menu_hidup:
			existing.stop()
			
func _tambah_tombol_suara() -> void:
	var btn := TextureButton.new()
	btn.name = "TombolSuara"
# Sesuaikan ikon dengan state saat ini (mungkin sudah diubah di scene lain)
	var ikon := ikon_suara_hidup if GameEvents.musik_menu_hidup else ikon_suara_mati
	btn.texture_normal  = ikon
	btn.texture_pressed = ikon
	btn.texture_hover   = ikon
	btn.ignore_texture_size = true
	btn.custom_minimum_size = Vector2(80, 80)
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Anchor ke pojok kanan bawah
	btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn.offset_left  = -120.0
	btn.offset_top   = -150.0
	btn.offset_right = -40.0
	btn.offset_bottom = -70.0

	btn.pressed.connect(func(): _toggle_suara(btn))
	add_child(btn)

func _toggle_suara(btn: TextureButton) -> void:
	GameEvents.musik_menu_hidup = not GameEvents.musik_menu_hidup
	var bgm := get_tree().root.get_node_or_null("BgmMenu")
	if GameEvents.musik_menu_hidup:
		if bgm: bgm.play()
		btn.texture_normal  = ikon_suara_hidup
		btn.texture_pressed = ikon_suara_hidup
		btn.texture_hover   = ikon_suara_hidup
	else:
		if bgm: bgm.stop()
		btn.texture_normal  = ikon_suara_mati
		btn.texture_pressed = ikon_suara_mati
		btn.texture_hover   = ikon_suara_mati
		
func _stop_bgm() -> void:
	var bgm := get_tree().root.get_node_or_null("BgmMenu")
	if bgm: bgm.stop()
	
func _on_button_start_pressed() -> void:
	_stop_bgm()
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
		# window.close() hanya works jika tab dibuka via script atau user klik link
		# Fallback: redirect ke blank jika close gagal
			JavaScriptBridge.eval("document.body.innerHTML = '<div style=\"display:flex;align-items:center;justify-content:center;height:100vh;font-family:sans-serif;font-size:24px;color:#555\">Terima kasih sudah bermain! Kamu bisa menutup tab ini.</div>';")
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
