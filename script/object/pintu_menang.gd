extends Area2D

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Setup sound efek:                                                         ║
# ║    1. Tambahkan node AudioStreamPlayer2D sebagai child node ini            ║
# ║    2. Drag node tersebut ke field "Sfx Buka" di Inspector                  ║
# ║    3. Assign audio stream (file .ogg/.wav) di node AudioStreamPlayer2D     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

## ID pintu ini. Di Inspector soal (.tres), buat WorldChangeEntry:
##   Action = OPEN_DOOR  |  Door Id = (angka yang sama dengan ini)
@export var door_id: int = 1

## AudioStreamPlayer2D untuk suara pintu terbuka. Buat sebagai child node.
@export var sfx_buka: AudioStreamPlayer2D

@onready var sprite = $Sprite2D
@export_file("*.tscn") var target_level_path: String

var is_open := false
var player_di_dekat_pintu := false

func _ready():
	GameEvents.quiz_answered_correct.connect(_on_quiz_solved)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.frame = 1  # Tertutup

# ─── World Change Handler ─────────────────────────────────────────────────────
func _on_quiz_solved(world_changes: Array):
	for entry: WorldChangeEntry in world_changes:
		if entry.action == WorldChangeEntry.ActionType.OPEN_DOOR and entry.door_id == door_id:
			# Kirim event cinematic ke CameraDirector:
			# kamera pan ke pintu → 0.3 detik → pintu terbuka + suara → kamera kembali
			CameraDirector.queue_cinematic(
				global_position,
				_buka_pintu,   # dipanggil saat kamera sudah tiba di pintu
				Callable()
			)
			break

func _buka_pintu():
	if is_open:
		return
	is_open = true
	sprite.frame = 0  # Visual pintu terbuka
	if sfx_buka != null:
		sfx_buka.play()

# ─── Interaksi Player ─────────────────────────────────────────────────────────
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_di_dekat_pintu = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_di_dekat_pintu = false

func _input(event):
	if event.is_action_pressed("interact") and player_di_dekat_pintu and is_open:
		_pindah_level()

func _pindah_level():
	if target_level_path != "":
		get_tree().call_deferred("change_scene_to_file", target_level_path)
