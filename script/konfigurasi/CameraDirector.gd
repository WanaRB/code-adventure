extends Node

const DURATION_PAN_TO     := 0.55
const DURATION_PAN_BACK   := 0.65
const DELAY_BEFORE_EFFECT := 0.3
const DELAY_AFTER_EFFECT  := 0.5

var _camera: Camera2D = null
var _is_busy := false
var _event_queue: Array[Dictionary] = []

func _ready():
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

	get_tree().paused = true

	var original_offset := _camera.offset
	var had_smoothing    := _camera.position_smoothing_enabled
	_camera.position_smoothing_enabled = false

	# ── FIX: Clamp target_pos agar tidak melewati Camera2D limits ──
	# Hitung setengah ukuran viewport dalam world-space (dibagi zoom)
	var vp_size    := _camera.get_viewport().get_visible_rect().size
	var cam_zoom   := _camera.zoom
	var half_w     := (vp_size.x / cam_zoom.x) * 0.5
	var half_h     := (vp_size.y / cam_zoom.y) * 0.5

	# Clamp agar center kamera tidak keluar dari batas map
	var clamped_pos := Vector2(
		clamp(target_pos.x, _camera.limit_left  + half_w, _camera.limit_right  - half_w),
		clamp(target_pos.y, _camera.limit_top   + half_h, _camera.limit_bottom - half_h)
	)

	var cam_world_pos  := _camera.get_screen_center_position()
	var target_offset  := original_offset + (clamped_pos - cam_world_pos)

	var tween_to := create_tween()
	tween_to.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_to.set_ease(Tween.EASE_IN_OUT)
	tween_to.set_trans(Tween.TRANS_CUBIC)
	tween_to.tween_property(_camera, "offset", target_offset, DURATION_PAN_TO)
	await tween_to.finished

	await get_tree().create_timer(DELAY_BEFORE_EFFECT, true).timeout
	if cb_before.is_valid():
		cb_before.call()

	await get_tree().create_timer(DELAY_AFTER_EFFECT, true).timeout

	var tween_back := create_tween()
	tween_back.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_back.set_ease(Tween.EASE_IN_OUT)
	tween_back.set_trans(Tween.TRANS_CUBIC)
	tween_back.tween_property(_camera, "offset", original_offset, DURATION_PAN_BACK)
	await tween_back.finished

	_camera.position_smoothing_enabled = had_smoothing
	get_tree().paused = false

	if cb_after.is_valid():
		cb_after.call()

	_process_next()
