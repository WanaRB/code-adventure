extends Node

# ─── Konfigurasi ───────────────────────────────────────────────────────────────
## Durasi kamera bergerak menuju target (detik)
const DURATION_PAN_TO     := 0.55
## Durasi kamera kembali ke player (detik)
const DURATION_PAN_BACK   := 0.65
## Jeda sebelum efek dunia terjadi setelah kamera tiba (detik)
const DELAY_BEFORE_EFFECT := 0.3
## Jeda setelah efek sebelum kamera kembali (detik)
const DELAY_AFTER_EFFECT  := 0.5

# ─── State ────────────────────────────────────────────────────────────────────
var _camera: Camera2D = null
var _is_busy := false
var _event_queue: Array[Dictionary] = []

func _ready():
	# Autoload ini harus selalu aktif bahkan ketika game di-pause
	process_mode = Node.PROCESS_MODE_ALWAYS

func register_camera(cam: Camera2D):
	_camera = cam

func queue_cinematic(target_position: Vector2, callback_before: Callable, callback_after: Callable = Callable()):
	_event_queue.append({
		"target": target_position,
		"before": callback_before,
		"after": callback_after,
	})
	if not _is_busy:
		_process_next()

func _process_next():
	if _event_queue.is_empty() or _camera == null:
		_is_busy = false
		return
	_is_busy = true
	var event: Dictionary = _event_queue.pop_front()
	_run_cinematic(event["target"], event["before"], event["after"])

func _run_cinematic(target_pos: Vector2, cb_before: Callable, cb_after: Callable):
	if _camera == null:
		if cb_before.is_valid(): cb_before.call()
		if cb_after.is_valid():  cb_after.call()
		_is_busy = false
		_process_next()
		return

	# ── Pause game agar player tidak bergerak saat cutscene ──
	get_tree().paused = true

	var original_offset := _camera.offset
	var had_smoothing    := _camera.position_smoothing_enabled
	_camera.position_smoothing_enabled = false

	var cam_world_pos  := _camera.get_screen_center_position()
	var target_offset  := original_offset + (target_pos - cam_world_pos)

	# ── Pan ke target (tween tidak terpengaruh pause) ──
	var tween_to := create_tween()
	tween_to.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_to.set_ease(Tween.EASE_IN_OUT)
	tween_to.set_trans(Tween.TRANS_CUBIC)
	tween_to.tween_property(_camera, "offset", target_offset, DURATION_PAN_TO)
	await tween_to.finished

	# ── Jeda → efek dunia terjadi ──
	# process_always = true agar timer tidak terpengaruh pause
	await get_tree().create_timer(DELAY_BEFORE_EFFECT, true).timeout
	if cb_before.is_valid():
		cb_before.call()

	# ── Jeda setelah efek ──
	await get_tree().create_timer(DELAY_AFTER_EFFECT, true).timeout

	# ── Pan kembali ke player ──
	var tween_back := create_tween()
	tween_back.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_back.set_ease(Tween.EASE_IN_OUT)
	tween_back.set_trans(Tween.TRANS_CUBIC)
	tween_back.tween_property(_camera, "offset", original_offset, DURATION_PAN_BACK)
	await tween_back.finished

	_camera.position_smoothing_enabled = had_smoothing

	# ── Unpause setelah cutscene selesai ──
	get_tree().paused = false

	if cb_after.is_valid():
		cb_after.call()

	_process_next()
