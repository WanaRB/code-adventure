extends Node

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                        CAMERA DIRECTOR                                     ║
# ║  Autoload singleton yang mengatur perpindahan kamera cinematic.            ║
# ║                                                                            ║
# ║  Setup di Project Settings → Autoload:                                     ║
# ║    Path: res://script/CameraDirector.gd                                    ║
# ║    Name: CameraDirector                                                    ║
# ║                                                                            ║
# ║  Di script Camera2D player (jikri.gd atau camera node), tambahkan:        ║
# ║    func _ready():                                                          ║
# ║        CameraDirector.register_camera(self)                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── Konfigurasi ───────────────────────────────────────────────────────────────
## Durasi kamera bergerak menuju target (detik)
const DURATION_PAN_TO   := 0.55
## Durasi kamera kembali ke player (detik)
const DURATION_PAN_BACK := 0.65
## Jeda sebelum efek dunia terjadi setelah kamera tiba (detik)
const DELAY_BEFORE_EFFECT := 0.3
## Jeda setelah efek sebelum kamera kembali (detik)
const DELAY_AFTER_EFFECT := 0.5

# ─── State ────────────────────────────────────────────────────────────────────
var _camera: Camera2D = null
var _is_busy := false
var _event_queue: Array[Dictionary] = []

# ─── API Publik ───────────────────────────────────────────────────────────────

## Dipanggil oleh Camera2D player saat _ready() agar CameraDirector mengenalnya.
func register_camera(cam: Camera2D):
	_camera = cam

## Tambahkan satu event cinematic ke antrian.
## callback_before: fungsi yang dipanggil saat kamera tiba di target (efek terjadi)
## callback_after:  fungsi yang dipanggil setelah kamera kembali ke player (opsional)
func queue_cinematic(target_position: Vector2, callback_before: Callable, callback_after: Callable = Callable()):
	_event_queue.append({
		"target": target_position,
		"before": callback_before,
		"after": callback_after,
	})
	if not _is_busy:
		_process_next()

# ─── Internal ─────────────────────────────────────────────────────────────────
func _process_next():
	if _event_queue.is_empty() or _camera == null:
		_is_busy = false
		return

	_is_busy = true
	var event: Dictionary = _event_queue.pop_front()
	_run_cinematic(event["target"], event["before"], event["after"])

func _run_cinematic(target_pos: Vector2, cb_before: Callable, cb_after: Callable):
	if _camera == null:
		# Tidak ada kamera terdaftar, langsung jalankan efek
		if cb_before.is_valid():
			cb_before.call()
		if cb_after.is_valid():
			cb_after.call()
		_is_busy = false
		_process_next()
		return

	# Simpan posisi awal dan matikan sementara drag/smoothing
	var original_offset := _camera.offset
	var had_smoothing := _camera.position_smoothing_enabled
	_camera.position_smoothing_enabled = false

	# Hitung offset relatif terhadap posisi kamera saat ini
	var cam_world_pos := _camera.get_screen_center_position()
	var target_offset := original_offset + (target_pos - cam_world_pos)

	# ── Pan ke target ──
	var tween_to := _camera.create_tween()
	tween_to.set_ease(Tween.EASE_IN_OUT)
	tween_to.set_trans(Tween.TRANS_CUBIC)
	tween_to.tween_property(_camera, "offset", target_offset, DURATION_PAN_TO)
	await tween_to.finished

	# ── Jeda lalu jalankan efek ──
	await _camera.get_tree().create_timer(DELAY_BEFORE_EFFECT).timeout
	if cb_before.is_valid():
		cb_before.call()

	# ── Jeda setelah efek ──
	await _camera.get_tree().create_timer(DELAY_AFTER_EFFECT).timeout

	# ── Pan kembali ke player ──
	var tween_back := _camera.create_tween()
	tween_back.set_ease(Tween.EASE_IN_OUT)
	tween_back.set_trans(Tween.TRANS_CUBIC)
	tween_back.tween_property(_camera, "offset", original_offset, DURATION_PAN_BACK)
	await tween_back.finished

	# Pulihkan smoothing
	_camera.position_smoothing_enabled = had_smoothing

	if cb_after.is_valid():
		cb_after.call()

	_process_next()
