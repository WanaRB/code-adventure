extends Node2D

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                      WORLD CHANGE MARKER                                   ║
# ║  Node tak terlihat yang jadi target kamera untuk efek yang tidak punya     ║
# ║  posisi spesifik (CONVERT_DRONES, MOVE_PLATFORM, dll).                    ║
# ║                                                                            ║
# ║  Cara pakai:                                                               ║
# ║    1. Tambahkan Node2D ke scene, attach script ini                         ║
# ║    2. Posisikan di area yang ingin disorot kamera                          ║
# ║    3. Set "Marker Action" sesuai aksi yang ingin disorot                   ║
# ║    4. Untuk MOVE_PLATFORM: isi juga "Marker Platform Id" agar hanya        ║
# ║       menyorot platform dengan ID yang sama                                ║
# ║    5. Tambah AudioStreamPlayer2D sebagai child (opsional)                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

## Aksi yang memicu marker ini.
@export var marker_action: WorldChangeEntry.ActionType = WorldChangeEntry.ActionType.CONVERT_DRONES

## [MOVE_PLATFORM] Filter: hanya aktif jika platform_id soal cocok dengan ini.
## Set ke 0 untuk cocok ke semua platform.
@export var marker_platform_id: int = 1

## AudioStreamPlayer2D untuk suara saat kamera tiba di marker.
@export var sfx_player: AudioStreamPlayer

func _ready():
	visible = false
	GameEvents.quiz_answered_correct.connect(_on_quiz_solved)

func _on_quiz_solved(world_changes: Array):
	for entry: WorldChangeEntry in world_changes:
		if entry.action != marker_action:
			continue

		# Untuk MOVE_PLATFORM: cek platform_id jika marker_platform_id != 0
		if marker_action == WorldChangeEntry.ActionType.MOVE_PLATFORM:
			if marker_platform_id != 0 and entry.platform_id != marker_platform_id:
				continue

		CameraDirector.queue_cinematic(global_position, _trigger_effect, Callable())
		break

func _trigger_effect():
	if sfx_player != null:
		sfx_player.play()
	_play_visual_effect()

## Override untuk tambah animasi visual (flash, partikel, dll). Kosong by default.
func _play_visual_effect():
	pass
