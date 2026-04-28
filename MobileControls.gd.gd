extends CanvasLayer

# ─── KONFIGURASI ──────────────────────────────────────────────────────────────
# Ukuran tombol (pixel) — perbesar jika terlalu kecil di HP kamu
const BTN_DIR_SIZE    := 400   ## Ukuran tombol KIRI dan KANAN
const BTN_JUMP_SIZE   := 400   ## Ukuran tombol LOMPAT
const BTN_E_SIZE      := 400    ## Ukuran tombol INTERAKSI (E)

# Posisi dari tepi layar (pixel)
# PAD_BOTTOM → naikkan angka = tombol naik dari bawah
# PAD_LEFT   → naikkan angka = tombol arah menjauh dari tepi kiri
# PAD_RIGHT  → naikkan angka = tombol lompat menjauh dari tepi kanan
const PAD_LEFT        := 500
const PAD_RIGHT       := 500
const PAD_BOTTOM      := 300
const GAP_DIR         := 500    ## Jarak antara tombol kiri dan kanan
const GAP_ACTION      := 400    ## Jarak antara tombol E dan lompat

const OPACITY_IDLE    := 0.75
const OPACITY_PRESSED := 0.95

# Path gambar — pastikan file ini ada di project
const IMG_KIRI   := "res://assets/image/MobileUI/dpad_element_east.png"
const IMG_KANAN  := "res://assets/image/MobileUI/dpad_element_west.png"
const IMG_LOMPAT := "res://assets/image/MobileUI/dpad_element_south.png"
const IMG_E      := "res://assets/image/MobileUI/button_circle.png"

# ─── State ────────────────────────────────────────────────────────────────────
var _finger_action : Dictionary = {}
var _button_rects  : Dictionary = {}
var _button_visuals: Dictionary = {}

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready():
	# Hanya muncul di web mobile (Android/iOS) — tidak di laptop/PC
	var is_mobile := OS.has_feature("web_android") or OS.has_feature("web_ios")
	#= (debug control) OS.has_feature("web_android") or OS.has_feature("web_ios")
	if not is_mobile:
		queue_free()
		return

	layer        = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

# ─── Build UI ─────────────────────────────────────────────────────────────────
func _build_ui():
	var W := float(get_viewport().get_visible_rect().size.x)
	var H := float(get_viewport().get_visible_rect().size.y)

	_tambah("kiri",
		Rect2(PAD_LEFT, H - PAD_BOTTOM - BTN_DIR_SIZE, BTN_DIR_SIZE, BTN_DIR_SIZE),
		IMG_KIRI, "", false)

	_tambah("kanan",
		Rect2(PAD_LEFT + BTN_DIR_SIZE + GAP_DIR,
			H - PAD_BOTTOM - BTN_DIR_SIZE, BTN_DIR_SIZE, BTN_DIR_SIZE),
		IMG_KANAN, "", false)

	_tambah("lompat",
		Rect2(W - PAD_RIGHT - BTN_JUMP_SIZE,
			H - PAD_BOTTOM - BTN_JUMP_SIZE, BTN_JUMP_SIZE, BTN_JUMP_SIZE),
		IMG_LOMPAT, "", false)

	_tambah("interact",
		Rect2(W - PAD_RIGHT - BTN_JUMP_SIZE - GAP_ACTION - BTN_E_SIZE,
			H - PAD_BOTTOM - BTN_E_SIZE, BTN_E_SIZE, BTN_E_SIZE),
		IMG_E, "E", false)

func _tambah(action: String, rect: Rect2, img: String, lbl_text: String, flip: bool):
	_button_rects[action] = rect
	var c := Control.new()
	c.position     = rect.position
	c.size         = rect.size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.modulate.a   = OPACITY_IDLE
	add_child(c)

	if img != "" and ResourceLoader.exists(img):
		var t := TextureRect.new()
		t.texture      = load(img)
		t.set_anchors_preset(Control.PRESET_FULL_RECT)
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.flip_v       = flip
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(t)

	if lbl_text != "":
		var l := Label.new()
		l.text = lbl_text
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", int(rect.size.x * 0.38))
		l.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(l)

	_button_visuals[action] = c

# ─── Multitouch input ─────────────────────────────────────────────────────────
func _input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			for action in _button_rects:
				if _button_rects[action].has_point(event.position):
					_press(event.index, action)
					break
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		if _finger_action.has(event.index):
			var cur: String = _finger_action[event.index]
			if not _button_rects[cur].has_point(event.position):
				_release(event.index)
				for action in _button_rects:
					if _button_rects[action].has_point(event.position):
						_press(event.index, action)
						break

func _press(finger: int, action: String):
	if _finger_action.get(finger, "") == action:
		return
	if _finger_action.has(finger):
		_release(finger)
	_finger_action[finger] = action
	Input.action_press(action)
	# Untuk interact: kirim event satu kali (just_pressed)
	if action == "interact":
		var ev := InputEventAction.new()
		ev.action  = "interact"
		ev.pressed = true
		Input.parse_input_event(ev)
	if _button_visuals.has(action):
		_button_visuals[action].modulate.a = OPACITY_PRESSED

func _release(finger: int):
	if not _finger_action.has(finger):
		return
	var action: String = _finger_action[finger]
	_finger_action.erase(finger)
	var masih_aktif := false
	for a in _finger_action.values():
		if a == action:
			masih_aktif = true
			break
	if not masih_aktif:
		Input.action_release(action)
	if _button_visuals.has(action):
		_button_visuals[action].modulate.a = OPACITY_IDLE

func _exit_tree():
	for action in _button_rects:
		Input.action_release(action)
