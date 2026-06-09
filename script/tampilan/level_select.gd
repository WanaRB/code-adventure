extends Control

@onready var vbox: VBoxContainer = $VBoxContainer

const STAR_PATHS := [
	"res://assets/image/UI/empty star.png",
	"res://assets/image/UI/1 star.png",
	"res://assets/image/UI/2 star.png",
	"res://assets/image/UI/3 star.png",
]
const THRESHOLD_1 := 100
const THRESHOLD_2 := 300
const THRESHOLD_3 := 500

func _ready() -> void:
	_animasi_masuk()
	_update_kunci()
	_update_bintang()

func _stop_bgm() -> void:
	var bgm := get_tree().root.get_node_or_null("BgmMenu")
	if bgm: bgm.stop()

func _update_kunci():
	for btn in find_children("*", "Button", true, false):
		if not btn is Button: continue
		for conn in btn.get_signal_connection_list("pressed"):
			var method: String = conn["callable"].get_method()
			if "level_2" in method:
				_terapkan_kunci(btn, 2)
			elif "level_3" in method:
				_terapkan_kunci(btn, 3)
			elif "level_4" in method:
				_terapkan_kunci(btn, 4)
			elif "level_5" in method:
				_terapkan_kunci(btn, 5)
			elif "level_6" in method:
				_terapkan_kunci(btn, 6)

func _terapkan_kunci(btn: Button, level: int):
	var terbuka := SaveManager.is_level_unlocked(level)
	btn.disabled = not terbuka

func _hitung_bintang(level: int) -> int:
	var poin := SaveManager.get_level_net_points(level)
	var maks := SaveManager.get_max_poin(level)
	if maks == 0: return 0
	var persen := float(poin) / float(maks) * 100.0
	if persen >= 100.0: return 3
	if persen >= 70.0:  return 2
	if persen >= 1.0:  return 1
	return 0

func _update_bintang() -> void:
	var btn_names := {
		1: "button_level1",
		2: "button_level2",
		3: "button_level3",
		4: "button_level4",
		5: "button_level5",
		6: "button_level6",
	}
	for level in btn_names:
		var btn: Button = vbox.find_child(btn_names[level]) as Button
		if btn == null: continue
		var bintang := _hitung_bintang(level)
		var path: String = STAR_PATHS[bintang]
		if not ResourceLoader.exists(path): continue
		var existing := btn.get_node_or_null("BintangLevel")
		if existing: existing.queue_free()
		var vb := VBoxContainer.new()
		vb.name = "BintangLevel"
		vb.set_anchors_preset(Control.PRESET_FULL_RECT)
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_theme_constant_override("separation", 4)
		btn.add_child(vb)
		var lbl := Label.new()
		lbl.text = btn.text
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 20)
		vb.add_child(lbl)
		btn.text = ""
		var star := TextureRect.new()
		star.texture = load(path)
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.custom_minimum_size = Vector2(80, 24)
		star.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(star)

func _on_button_level_1_pressed() -> void:
	_stop_bgm()
	_animasi_keluar("res://scenes/Level/level_1.tscn")

func _on_button_level_2_pressed() -> void:
	if SaveManager.is_level_unlocked(2):
		_stop_bgm()
		_animasi_keluar("res://scenes/Level/level_2.tscn")

func _on_button_level_3_pressed() -> void:
	if SaveManager.is_level_unlocked(3):
		_stop_bgm()
		_animasi_keluar("res://scenes/Level/level_3.tscn")

func _on_button_level_4_pressed() -> void:
	if SaveManager.is_level_unlocked(4):
		_stop_bgm()
		_animasi_keluar("res://scenes/Level/level_4.tscn")

func _on_button_level_5_pressed() -> void:
	if SaveManager.is_level_unlocked(5):
		_stop_bgm()
		_animasi_keluar("res://scenes/Level/level_5.tscn")

func _on_button_level_6_pressed() -> void:
	if SaveManager.is_level_unlocked(6):
		_stop_bgm()
		_animasi_keluar("res://scenes/Level/level_6.tscn")

func _on_button_back_pressed() -> void:
	_animasi_keluar("res://scenes/UI/play_menu.tscn")

func _animasi_masuk() -> void:
	vbox.modulate.a = 0.0
	vbox.position.y += 600.0
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.1)
	tw.tween_property(vbox, "modulate:a", 1.0, 0.5)
	tw.parallel().tween_property(vbox, "position:y", vbox.position.y - 600.0, 0.7)
	tw.tween_callback(func(): vbox.mouse_filter = Control.MOUSE_FILTER_STOP)

func _animasi_keluar(target_scene: String) -> void:
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(vbox, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(vbox, "position:y", vbox.position.y + 600.0, 0.4)
	tw.tween_callback(func(): get_tree().change_scene_to_file(target_scene))
