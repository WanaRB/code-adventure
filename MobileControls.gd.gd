extends CanvasLayer

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                    KONFIGURASI MOBILE CONTROLS                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

## Tampilkan kontrol di PC juga (untuk testing di editor). Set false saat publish.
const SELALU_TAMPIL      := false

## Ukuran tombol kiri/kanan (pixel)
const BTN_DIR_SIZE       := 75.0
## Ukuran tombol lompat (pixel)
const BTN_JUMP_SIZE      := 90.0
## Ukuran tombol interaksi E (pixel)
const BTN_E_SIZE         := 65.0

## Opacity tombol idle
const OPACITY_IDLE       := 0.45
## Opacity tombol saat ditekan
const OPACITY_PRESSED    := 0.90

## Jarak dari tepi kiri layar (pixel)
const PAD_LEFT           := 20.0
## Jarak dari tepi kanan layar (pixel)
const PAD_RIGHT          := 20.0
## Jarak dari tepi bawah layar (pixel)
const PAD_BOTTOM         := 28.0
## Jarak antar tombol kiri-kanan (pixel)
const GAP_DIR            := 10.0

## Warna tombol arah
const C_DIR              := Color("#89b4fa")
## Warna tombol lompat
const C_JUMP             := Color("#a6e3a1")
## Warna tombol interaksi
const C_INTERACT         := Color("#f9e2af")

# ─── State internal ────────────────────────────────────────────────────────────
# Map: finger_index → action name yang sedang ditekan oleh jari itu
var _finger_action: Dictionary = {}

# Referensi rect setiap tombol (Rect2 dalam koordinat layar)
# Format: { "action_name": Rect2 }
var _button_rects: Dictionary = {}

# Referensi visual node setiap tombol
var _button_visuals: Dictionary = {}

# ─── Setup ────────────────────────────────────────────────────────────────────
func _ready():
	if not DisplayServer.is_touchscreen_available() and not SELALU_TAMPIL:
		queue_free()
		return

	layer = 10
	# KRITIS: process harus ALWAYS agar bisa terima input saat game di-pause (quiz, dll.)
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build_ui()

# ─── Build UI ─────────────────────────────────────────────────────────────────
func _build_ui():
	var vp := get_viewport()
	var W: float = vp.get_visible_rect().size.x
	var H: float = vp.get_visible_rect().size.y

	# ── Kiri: tombol ← ──
	var r_kiri := Rect2(
		PAD_LEFT,
		H - PAD_BOTTOM - BTN_DIR_SIZE,
		BTN_DIR_SIZE, BTN_DIR_SIZE
	)
	_tambah_tombol("kiri", r_kiri, "◀", C_DIR)

	# ── Kanan: tombol → ──
	var r_kanan := Rect2(
		PAD_LEFT + BTN_DIR_SIZE + GAP_DIR,
		H - PAD_BOTTOM - BTN_DIR_SIZE,
		BTN_DIR_SIZE, BTN_DIR_SIZE
	)
	_tambah_tombol("kanan", r_kanan, "▶", C_DIR)

	# ── Lompat: tombol ↑ (kanan bawah) ──
	var r_lompat := Rect2(
		W - PAD_RIGHT - BTN_JUMP_SIZE,
		H - PAD_BOTTOM - BTN_JUMP_SIZE,
		BTN_JUMP_SIZE, BTN_JUMP_SIZE
	)
	_tambah_tombol("lompat", r_lompat, "▲", C_JUMP)

	# ── Interact: tombol E (kiri dari lompat) ──
	var r_e := Rect2(
		W - PAD_RIGHT - BTN_JUMP_SIZE - BTN_E_SIZE - GAP_DIR,
		H - PAD_BOTTOM - BTN_E_SIZE,
		BTN_E_SIZE, BTN_E_SIZE
	)
	_tambah_tombol("interact", r_e, "E", C_INTERACT)

func _tambah_tombol(action: String, rect: Rect2, label: String, warna: Color):
	_button_rects[action] = rect

	# Visual: ColorRect bulat sebagai background
	var bg := ColorRect.new()
	bg.position = rect.position
	bg.size      = rect.size
	bg.color     = Color(warna.r, warna.g, warna.b, 0.18)
	bg.modulate.a = OPACITY_IDLE

	# Sudut bulat via shader tidak tersedia di compatibility renderer —
	# pakai Label di atas sebagai tanda visual
	add_child(bg)

	var lbl := Label.new()
	lbl.text = label
	lbl.position = rect.position
	lbl.size = rect.size
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", int(rect.size.x * 0.45))
	lbl.add_theme_color_override("font_color", warna)
	add_child(lbl)

	_button_visuals[action] = bg

# ─── Input Handling (multitouch) ──────────────────────────────────────────────
func _input(event: InputEvent):
	if event is InputEventScreenTouch:
		_handle_touch(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_handle_drag(event.index, event.position)

func _handle_touch(finger: int, pos: Vector2, pressed: bool):
	if pressed:
		# Jari baru menyentuh layar — cek apakah mengenai tombol
		for action in _button_rects:
			if _button_rects[action].has_point(pos):
				_press(finger, action)
				return
	else:
		# Jari diangkat — lepaskan tombol yang dipegangnya
		if _finger_action.has(finger):
			_release(finger)

func _handle_drag(finger: int, pos: Vector2):
	# Jika jari bergeser keluar dari tombolnya, lepaskan tombol itu
	if _finger_action.has(finger):
		var current_action: String = _finger_action[finger]
		if not _button_rects[current_action].has_point(pos):
			_release(finger)

		# Cek apakah jari bergeser ke tombol lain
		for action in _button_rects:
			if action != current_action and _button_rects[action].has_point(pos):
				_release(finger)
				_press(finger, action)
				return

func _press(finger: int, action: String):
	_finger_action[finger] = action
	# Inject langsung ke sistem Input Godot — works dengan multitouch
	Input.action_press(action)
	# Visual feedback
	if _button_visuals.has(action):
		_button_visuals[action].modulate.a = OPACITY_PRESSED
	# Untuk "interact": inject event sekali (bukan hold)
	if action == "interact":
		var ev := InputEventAction.new()
		ev.action  = "interact"
		ev.pressed = true
		Input.parse_input_event(ev)

func _release(finger: int):
	if not _finger_action.has(finger):
		return
	var action: String = _finger_action[finger]
	_finger_action.erase(finger)
	Input.action_release(action)
	if _button_visuals.has(action):
		_button_visuals[action].modulate.a = OPACITY_IDLE

# ─── Cleanup saat scene ganti ─────────────────────────────────────────────────
func _exit_tree():
	# Pastikan tidak ada action yang tersangkut saat scene di-reload
	for action in _button_rects:
		Input.action_release(action)
