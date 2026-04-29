extends AnimatableBody2D

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                    PLATFORM BERGERAK — v3                                  ║
# ║                                                                            ║
# ║  Script ini harus di-attach ke node ROOT yang bertipe AnimatableBody2D.   ║
# ║                                                                            ║
# ║  Struktur scene yang benar:                                                ║
# ║    AnimatableBody2D  ← root, attach script ini di sini                    ║
# ║    ├── Sprite2D      ← visual platform                                     ║
# ║    └── CollisionShape2D ← collision platform                               ║
# ║                                                                            ║
# ║  JANGAN ada Node2D di tengah. Script, Sprite2D, dan CollisionShape2D      ║
# ║  semua langsung di bawah AnimatableBody2D.                                 ║
# ║                                                                            ║
# ║  sync_to_physics dibiarkan false (default) karena kita pakai              ║
# ║  move_and_collide secara manual di _physics_process.                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

enum Direction {
	## Mulai bergerak ke kiri, lalu balik ke kanan, berulang.
	KIRI_KANAN = 0,
	## Mulai bergerak ke kanan, lalu balik ke kiri, berulang.
	KANAN_KIRI = 1,
	## Mulai bergerak ke bawah, lalu balik ke atas, berulang.
	BAWAH_ATAS = 2,
	## Mulai bergerak ke atas, lalu balik ke bawah, berulang.
	ATAS_BAWAH = 3,
}

# ─── Inspector ────────────────────────────────────────────────────────────────
## ID platform. Cocokkan dengan Platform Id di WorldChangeEntry soal.
@export var platform_id: int = 1

## Arah gerakan setelah diaktifkan.
@export var direction: Direction = Direction.KIRI_KANAN

## Jarak pergerakan dari posisi awal (pixel).
@export var jarak: float = 200.0

## Kecepatan pergerakan (pixel per detik).
@export var kecepatan: float = 80.0

## AudioStreamPlayer2D untuk suara platform mulai bergerak.
@export var sfx_aktif: AudioStreamPlayer

# ─── State ────────────────────────────────────────────────────────────────────
var _bergerak      := false
var _posisi_awal   := Vector2.ZERO
var _posisi_tujuan := Vector2.ZERO
var _elapsed       := 0.0
var _cycle_dur     := 1.0   # detik per setengah siklus

func _ready():
	# sync_to_physics = false (default untuk AnimatableBody2D yang dikontrol manual)
	# Tidak perlu diset secara eksplisit karena sudah default false,
	# tapi dituliskan di sini agar jelas.
	sync_to_physics = false

	_posisi_awal = global_position

	match direction:
		Direction.KIRI_KANAN:  _posisi_tujuan = _posisi_awal + Vector2(-jarak,  0)
		Direction.KANAN_KIRI:  _posisi_tujuan = _posisi_awal + Vector2( jarak,  0)
		Direction.BAWAH_ATAS:  _posisi_tujuan = _posisi_awal + Vector2(0,  jarak)
		Direction.ATAS_BAWAH:  _posisi_tujuan = _posisi_awal + Vector2(0, -jarak)

	_cycle_dur = jarak / max(kecepatan, 1.0)

	GameEvents.quiz_answered_correct.connect(_on_quiz_solved)

# ─── Physics Process ─────────────────────────────────────────────────────────
func _physics_process(delta: float):
	if not _bergerak:
		return

	_elapsed += delta

	# Ping-pong: 0→1 (awal→tujuan) lalu 1→0 (tujuan→awal), berulang
	var phase := fmod(_elapsed, _cycle_dur * 2.0)
	var t     := phase / _cycle_dur
	if t > 1.0:
		t = 2.0 - t

	# Smoothstep (ease-in-out) agar gerakan terasa natural
	t = t * t * (3.0 - 2.0 * t)

	var target_pos := _posisi_awal.lerp(_posisi_tujuan, t)
	var delta_pos  := target_pos - global_position

	# move_and_collide pada self (AnimatableBody2D):
	# - Menggerakkan collision body SATU KALI saja (tidak ada double movement)
	# - Mendorong/membawa RigidBody dan CharacterBody yang berada di atasnya
	move_and_collide(delta_pos)

# ─── World Change Handler ─────────────────────────────────────────────────────
func _on_quiz_solved(world_changes: Array):
	for entry: WorldChangeEntry in world_changes:
		if entry.action == WorldChangeEntry.ActionType.MOVE_PLATFORM \
		   and entry.platform_id == platform_id \
		   and not _bergerak:
			CameraDirector.queue_cinematic(global_position, _mulai_bergerak, Callable())
			break

func _mulai_bergerak():
	if _bergerak:
		return
	_bergerak = true
	_elapsed   = 0.0
	if sfx_aktif != null:
		sfx_aktif.play()
