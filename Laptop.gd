extends Area2D

# Slot untuk memasukkan file kuis (.tres) dan tampilan kuis (.tscn)
@export var data_kuis: QuizResource
@export var scene_ui_kuis: PackedScene

var player_didalam_area = false

func _ready():
	# Menghubungkan sinyal deteksi otomatis
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Laptop hanya bereaksi jika yang mendekat masuk grup "player"
	if body.is_in_group("player"):
		player_didalam_area = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_didalam_area = false

func _input(event):
	# Jika tombol "E" ditekan dan pemain ada di dekat laptop
	if event.is_action_pressed("interact") and player_didalam_area:
		buka_kuis()

func buka_kuis():
	# Memunculkan kuis di layar [cite: 26]
	GameEvents.quiz_opened.emit()
	var instance_kuis = scene_ui_kuis.instantiate()
	get_tree().root.add_child(instance_kuis)
	
	# Kirim data soal ke UI tersebut
	instance_kuis.setup_quiz(data_kuis)
	
	# Hentikan gerakan game agar pemain fokus menjawab
	get_tree().paused = true
