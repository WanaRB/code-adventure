extends Area2D

@export var data_kuis: QuizResource
@export var scene_ui_kuis: PackedScene
@export var bisa_jawab_ulang: bool = true

var player_didalam_area = false
var _kuis_sedang_terbuka := false
var _highlight_display: Array[String] = []
var _variant_sudah_benar: Array[int] = []
var _label_interaksi: Node2D = null
var _sudah_selesai := false

func _ready():
	# buat UI
	_buat_label_interaksi()
	# connect signals
	GameEvents.quiz_answered_correct.connect(_on_quiz_answered_correct)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameEvents.quiz_closed.connect(func(): _kuis_sedang_terbuka = false)
	GameEvents.quiz_highlight_updated.connect(_on_highlight_updated)
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_didalam_area = true
		if _label_interaksi and not _sudah_selesai:
			_label_interaksi.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_didalam_area = false
		if _label_interaksi: _label_interaksi.visible = false

func _input(event):
	if event.is_action_pressed("interact") and player_didalam_area:
		buka_kuis()

func buka_kuis():
	if _kuis_sedang_terbuka: return
	if _sudah_selesai: return
	_kuis_sedang_terbuka = true
	GameEvents.quiz_opened.emit()
	var instance_kuis = scene_ui_kuis.instantiate()
	get_tree().root.add_child(instance_kuis)
	instance_kuis.setup_quiz(data_kuis, _highlight_display, _variant_sudah_benar)
	get_tree().paused = true

func _on_highlight_updated(hl_idx: int, teks: String) -> void:
	if not _kuis_sedang_terbuka:  # ← hanya update jika laptop INI yang aktif
		return
	if _highlight_display.size() <= hl_idx:
		_highlight_display.resize(hl_idx + 1)
	_highlight_display[hl_idx] = teks

func _on_quiz_answered_correct(variant_idx: int, _world_changes) -> void:
	if not _kuis_sedang_terbuka: return
	if variant_idx not in _variant_sudah_benar:
		_variant_sudah_benar.append(variant_idx)
	if not bisa_jawab_ulang:
		_sudah_selesai = true
		if _label_interaksi:
			_label_interaksi.visible = false

func _buat_label_interaksi() -> void:
	var container := Node2D.new()
	container.position = Vector2(0, -90)
	container.visible = false
	add_child(container)
	_label_interaksi = container

	var label := Label.new()
	label.text = "Tekan [E] untuk interaksi"
	label.add_theme_font_size_override("font_size", 25)
	label.add_theme_color_override("font_color", Color("ffffffff"))
	label.add_theme_color_override("font_outline_color", Color("000000ff"))
	label.add_theme_constant_override("outline_size", 4)
	label.position = Vector2(-130, -10)
	container.add_child(label)
