extends Node

const DURATION_PAN_TO     := 0.55
const DURATION_PAN_BACK   := 0.65
const DELAY_BEFORE_EFFECT := 0.3
const DELAY_AFTER_EFFECT  := 2.0

var _camera: Camera2D = null
var _is_busy := false
var _event_queue: Array[Dictionary] = []

var _follow_node: Node2D = null
var _follow_base_offset := Vector2.ZERO
var _follow_start_node_pos := Vector2.ZERO

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func register_camera(cam: Camera2D):
	_camera = cam

func queue_cinematic(
	target_position: Vector2,
	callback_before: Callable,
	callback_after: Callable = Callable(),
	delay_after: float = DELAY_AFTER_EFFECT,
	follow_node: Node2D = null
):
	_event_queue.append({
		"target": target_position,
		"before": callback_before,
		"after": callback_after,
		"delay_after": delay_after,
		"follow_node": follow_node,
	})
	if not _is_busy:
		_process_next()

func _process_next():
	if _event_queue.is_empty() or _camera == null:
		_is_busy = false
		return

	_is_busy = true
	var event: Dictionary = _event_queue.pop_front()
	_run_cinematic(
		event["target"],
		event["before"],
		event["after"],
		event["delay_after"],
		event["follow_node"]
	)

func _run_cinematic(
	target_pos: Vector2,
	cb_before: Callable,
	cb_after: Callable,
	delay_after: float,
	follow_node: Node2D
):
	if _camera == null:
		if cb_before.is_valid():
			cb_before.call()
		if cb_after.is_valid():
			cb_after.call()
		_is_busy = false
		_process_next()
		return

	get_tree().paused = true

	var original_offset := _camera.offset
	var had_smoothing := _camera.position_smoothing_enabled
	_camera.position_smoothing_enabled = false

	var vp_size := _camera.get_viewport().get_visible_rect().size
	var cam_zoom := _camera.zoom
	var half_w := (vp_size.x / cam_zoom.x) * 0.5
	var half_h := (vp_size.y / cam_zoom.y) * 0.5

	var clamped_pos := Vector2(
		clamp(target_pos.x, _camera.limit_left + half_w, _camera.limit_right - half_w),
		clamp(target_pos.y, _camera.limit_top + half_h, _camera.limit_bottom - half_h)
	)

	var cam_world_pos := _camera.get_screen_center_position()
	var target_offset := original_offset + (clamped_pos - cam_world_pos)

	var tween_to := create_tween()
	tween_to.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_to.set_ease(Tween.EASE_IN_OUT)
	tween_to.set_trans(Tween.TRANS_CUBIC)
	tween_to.tween_property(_camera, "offset", target_offset, DURATION_PAN_TO)
	await tween_to.finished

	await get_tree().create_timer(DELAY_BEFORE_EFFECT, true).timeout

	if cb_before.is_valid():
		cb_before.call()

	if follow_node != null and is_instance_valid(follow_node):
		_follow_node = follow_node
		_follow_base_offset = _camera.offset
		_follow_start_node_pos = follow_node.global_position

	await get_tree().create_timer(delay_after, true).timeout

	_follow_node = null

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

	_is_busy = false
	_process_next()

func _process(_delta: float) -> void:
	if _follow_node == null or _camera == null or not _is_busy:
		return

	if not is_instance_valid(_follow_node):
		_follow_node = null
		return

	var delta_pos := _follow_node.global_position - _follow_start_node_pos
	_camera.offset = _follow_base_offset + delta_pos
