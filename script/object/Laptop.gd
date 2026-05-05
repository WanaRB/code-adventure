extends Area2D

@export var data_kuis: QuizResource
@export var scene_ui_kuis: PackedScene

var player_didalam_area = false
var _kuis_sedang_terbuka := false
var _highlight_display: Array[String] = []

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameEvents.quiz_closed.connect(func(): _kuis_sedang_terbuka = false)
	GameEvents.quiz_highlight_updated.connect(_on_highlight_updated)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_didalam_area = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_didalam_area = false

func _input(event):
	if event.is_action_pressed("interact") and player_didalam_area:
		buka_kuis()

func buka_kuis():
	if _kuis_sedang_terbuka: return
	_kuis_sedang_terbuka = true
	GameEvents.quiz_opened.emit()
	var instance_kuis = scene_ui_kuis.instantiate()
	get_tree().root.add_child(instance_kuis)
	instance_kuis.setup_quiz(data_kuis, _highlight_display)
	get_tree().paused = true

func _on_highlight_updated(hl_idx: int, teks: String) -> void:
	if not _kuis_sedang_terbuka:  # ← hanya update jika laptop INI yang aktif
		return
	if _highlight_display.size() <= hl_idx:
		_highlight_display.resize(hl_idx + 1)
	_highlight_display[hl_idx] = teks
