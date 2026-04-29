extends Area2D

@export var data_kuis: QuizResource
@export var scene_ui_kuis: PackedScene

var player_didalam_area = false
var _kuis_sedang_terbuka := false
var _kuis_sudah_selesai := false  # ← TAMBAH: true setelah semua soal dijawab benar

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameEvents.quiz_closed.connect(func(): _kuis_sedang_terbuka = false)
	# ← TAMBAH: deteksi quiz selesai benar agar laptop dikunci
	GameEvents.quiz_answered_correct.connect(_on_quiz_benar_semua)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_didalam_area = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_didalam_area = false

## Dipanggil saat semua soal quiz dijawab benar.
## Jika laptop INI yang sedang aktif (_kuis_sedang_terbuka), kunci permanen.
func _on_quiz_benar_semua(_world_changes):  # ← TAMBAH fungsi ini
	if _kuis_sedang_terbuka:
		_kuis_sudah_selesai = true

func _input(event):
	if event.is_action_pressed("interact") and player_didalam_area:
		buka_kuis()

func buka_kuis():
	# ← TAMBAH _kuis_sudah_selesai: laptop dikunci setelah quiz selesai benar
	if _kuis_sedang_terbuka or _kuis_sudah_selesai: return
	_kuis_sedang_terbuka = true
	GameEvents.quiz_opened.emit()
	var instance_kuis = scene_ui_kuis.instantiate()
	get_tree().root.add_child(instance_kuis)
	instance_kuis.setup_quiz(data_kuis)
	get_tree().paused = true
