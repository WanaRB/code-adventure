extends CanvasLayer

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║              KONFIGURASI UKURAN & POSISI TOMBOL MOBILE                     ║
# ║                                                                            ║
# ║  Semua angka dalam pixel. Koordinat (0,0) = pojok kiri atas layar.         ║
# ║                                                                            ║
# ║  Cara mengatur posisi tombol:                                              ║
# ║    PAD_LEFT   → geser tombol KIRI/KANAN menjauhi tepi kiri                 ║
# ║    PAD_RIGHT  → geser tombol LOMPAT/E menjauhi tepi kanan                  ║
# ║    PAD_BOTTOM → naikkan semua tombol dari tepi bawah (angka lebih besar   ║
# ║                 = tombol lebih tinggi dari bawah layar)                    ║
# ║    GAP_DIR    → jarak antara tombol KIRI dan KANAN                         ║
# ║    GAP_ACTION → jarak antara tombol E dan LOMPAT                           ║
# ║                                                                            ║
# ║  Cara mengatur ukuran tombol:                                              ║
# ║    BTN_DIR_SIZE    → ukuran tombol ◄ dan ► (lebih besar = lebih mudah tap) ║
# ║    BTN_JUMP_SIZE   → ukuran tombol LOMPAT (sedikit lebih besar dari arah)  ║
# ║    BTN_E_SIZE      → ukuran tombol INTERAKSI (E)                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── Ukuran tombol ────────────────────────────────────────────────────────────
const BTN_DIR_SIZE    := 200.0   ## Ukuran tombol kiri & kanan (pixel)
const BTN_JUMP_SIZE   := 200.0  ## Ukuran tombol lompat (pixel)
const BTN_E_SIZE      := 200.0   ## Ukuran tombol interaksi E (pixel)

# ─── Posisi (jarak dari tepi layar) ──────────────────────────────────────────
const PAD_LEFT        := 200.0   ## Jarak tombol kiri dari tepi kiri layar
const PAD_RIGHT       := 200.0   ## Jarak tombol lompat dari tepi kanan layar
const PAD_BOTTOM      := 200.0   ## Jarak semua tombol dari tepi bawah layar
const GAP_DIR         := 200.0   ## Jarak antara tombol kiri dan kanan
const GAP_ACTION      := 100.0   ## Jarak antara tombol E dan Lompat

# ─── Tampilan ─────────────────────────────────────────────────────────────────
const OPACITY_IDLE    := 0.70   ## Transparansi tombol saat tidak ditekan (0.0–1.0)
const OPACITY_PRESSED := 0.95   ## Transparansi tombol saat ditekan

# ─── Path gambar tombol ───────────────────────────────────────────────────────
# Tombol kiri  → dpad_element_west.png
# Tombol kanan → dpad_element_east.png
# Tombol lompat → dpad_element_south.png  (dibalik vertikal agar panah ke atas)
# Tombol E     → button_circle.png + label "E"
const IMG_KIRI   := "res://assets/image/MobileUI/dpad_element_east.png"
const IMG_KANAN  := "res://assets/image/MobileUI/dpad_element_west.png"
const IMG_LOMPAT := "res://assets/image/MobileUI/dpad_element_south.png"
const IMG_E      := "res://assets/image/MobileUI/button_circle.png"

# ─── State internal ────────────────────────────────────────────────────────────
var _finger_action : Dictionary = {}   # finger_index → action string
var _button_rects  : Dictionary = {}   # action string → Rect2
var _button_visuals: Dictionary = {}   # action string → Control node

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready():
	# Deteksi mobile: cek fitur platform Godot (reliable di HTML5)
	var is_mobile := OS.has_feature("web_android") or OS.has_feature("web_ios")
	if not is_mobile:
		queue_free()
		return

	layer        = 10
	process_mode = Node.PROCESS_MODE_ALWAYS   # Tetap aktif saat game di-pause
	_build_ui()

# ─── Build UI ─────────────────────────────────────────────────────────────────
func _build_ui():
	var W := float(get_viewport().get_visible_rect().size.x)
	var H := float(get_viewport().get_visible_rect().size.y)

	# ── Tombol KIRI ──
	_tambah_gambar("kiri",
		Rect2(PAD_LEFT, H - PAD_BOTTOM - BTN_DIR_SIZE, BTN_DIR_SIZE, BTN_DIR_SIZE),
		IMG_KIRI, "", false)

	# ── Tombol KANAN ──
	_tambah_gambar("kanan",
		Rect2(PAD_LEFT + BTN_DIR_SIZE + GAP_DIR, H - PAD_BOTTOM - BTN_DIR_SIZE,
			BTN_DIR_SIZE, BTN_DIR_SIZE),
		IMG_KANAN, "", false)

	# ── Tombol LOMPAT (kanan bawah) — gambar dibalik agar panah ke atas ──
	_tambah_gambar("lompat",
		Rect2(W - PAD_RIGHT - BTN_JUMP_SIZE, H - PAD_BOTTOM - BTN_JUMP_SIZE,
			BTN_JUMP_SIZE, BTN_JUMP_SIZE),
		IMG_LOMPAT, "", false)   # flip = true

	# ── Tombol E / INTERACT (kiri dari lompat) ──
	_tambah_gambar("interact",
		Rect2(W - PAD_RIGHT - BTN_JUMP_SIZE - GAP_ACTION - BTN_E_SIZE,
			H - PAD_BOTTOM - BTN_E_SIZE, BTN_E_SIZE, BTN_E_SIZE),
		IMG_E, "E", false)

func _tambah_gambar(action: String, rect: Rect2,
		img_path: String, label_text: String, flip_v: bool):
	_button_rects[action] = rect

	# Container agar gambar + label bisa ditumpuk
	var container := Control.new()
	container.position = rect.position
	container.size     = rect.size
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)

	# Gambar tombol
	if img_path != "" and ResourceLoader.exists(img_path):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(img_path)
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if flip_v:
			tex_rect.flip_v = true
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(tex_rect)

	# Label opsional (untuk tombol E)
	if label_text != "":
		var lbl := Label.new()
		lbl.text = label_text
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", int(rect.size.x * 0.40))
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(lbl)

	container.modulate.a    = OPACITY_IDLE
	_button_visuals[action] = container

# ─── Input multitouch ─────────────────────────────────────────────────────────
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
			# Jari keluar dari tombolnya → lepas
			if not _button_rects[cur].has_point(event.position):
				_release(event.index)
				# Pindah ke tombol lain jika ada
				for action in _button_rects:
					if _button_rects[action].has_point(event.position):
						_press(event.index, action)
						break

func _press(finger: int, action: String):
	if _finger_action.get(finger, "") == action:
		return   # Sudah aktif, tidak perlu dobel
	if _finger_action.has(finger):
		_release(finger)   # Lepas tombol lama dulu
	_finger_action[finger] = action
	Input.action_press(action)
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
	# Hanya release jika tidak ada jari lain yang memegang tombol yang sama
	var masih_dipegang := false
	for a in _finger_action.values():
		if a == action:
			masih_dipegang = true
			break
	if not masih_dipegang:
		Input.action_release(action)
	if _button_visuals.has(action):
		_button_visuals[action].modulate.a = OPACITY_IDLE

# ─── Cleanup ──────────────────────────────────────────────────────────────────
func _exit_tree():
	for action in _button_rects:
		Input.action_release(action)
