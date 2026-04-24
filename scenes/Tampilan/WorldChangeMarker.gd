extends Node2D

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                      WORLD CHANGE MARKER                                   ║
# ║  Node tak terlihat yang jadi target kamera untuk efek CONVERT_DRONES       ║
# ║  (atau aksi lain yang tidak punya posisi spesifik).                        ║
# ║                                                                            ║
# ║  Cara pakai di Godot Editor:                                               ║
# ║    1. Tambahkan Node2D ke scene, attach script ini                         ║
# ║    2. Posisikan node di tengah kerumunan drone (atau area yang ingin       ║
# ║       disorot kamera)                                                       ║
# ║    3. Set "Marker Action" = CONVERT_DRONES (atau aksi lain)               ║
# ║    4. Assign AudioStreamPlayer2D ke field "Sfx Player" (opsional)         ║
# ║    5. Node ini otomatis tak terlihat di runtime                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

## Aksi yang memicu marker ini. Harus cocok dengan WorldChangeEntry.ActionType.
@export var marker_action: WorldChangeEntry.ActionType = WorldChangeEntry.ActionType.CONVERT_DRONES

## [Opsional] AudioStreamPlayer2D untuk suara efek saat aksi terjadi.
## Tambahkan node AudioStreamPlayer2D sebagai child, drag ke sini,
## lalu assign audio stream di node tersebut.
@export var sfx_player: AudioStreamPlayer2D

## Durasi ikon/flash visual marker terlihat sebelum memudar (jika kamu ingin
## menambahkan animasi visual sendiri, override _play_visual_effect()).
@export var visual_duration: float = 0.4

func _ready():
	# Tak terlihat di runtime (tapi tetap bisa dipilih di editor)
	visible = false
	GameEvents.quiz_answered_correct.connect(_on_quiz_solved)

func _on_quiz_solved(world_changes: Array):
	for entry: WorldChangeEntry in world_changes:
		if entry.action == marker_action:
			CameraDirector.queue_cinematic(
				global_position,
				_trigger_effect,   # dipanggil saat kamera tiba
				Callable()
			)
			break  # Satu marker cukup satu kali per sinyal

func _trigger_effect():
	# Mainkan suara efek jika ada
	if sfx_player != null:
		sfx_player.play()

	# Panggil fungsi visual jika kamu ingin tambahkan animasi
	_play_visual_effect()

## Override function ini jika ingin tambah animasi visual di marker
## (misal: flash cahaya, partikel, dll). Kosong by default.
func _play_visual_effect():
	pass
