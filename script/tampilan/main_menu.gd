extends Control

var _confirm_dialog: Panel = null
var _is_showing_confirm := false

# Referensi node yang perlu diubah warna
@onready var _panel: Panel = $Panel
@onready var _vbox: VBoxContainer = $VBoxContainer
@onready var bgm_menu: AudioStreamPlayer = %BgmMenu

func _ready() -> void:
	pass


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
