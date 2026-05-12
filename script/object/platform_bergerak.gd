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
var _resetting       := false   # true saat platform sedang glide balik ke posisi awal
var _reset_dur       := 1.0     # durasi glide balik (detik)
var _reset_elapsed   := 0.0     # waktu berjalan selama fase reset
var _posisi_saat_reset := Vector2.ZERO  # posisi platform saat reset dimulai
var _pending_tujuan  := Vector2.ZERO    # tujuan baru yang menunggu setelah reset selesai
var _pending_kecepatan := 0.0           # kecepatan baru yang menunggu
var _on_selesai: Callable = Callable()  # callback ke CameraDirector saat animasi selesai

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
func _physics_process(delta: float) -> void:
	if _resetting:
		# Fase 1: glide smooth balik ke posisi awal
		_reset_elapsed += delta
		var t: float = clamp(_reset_elapsed / _reset_dur, 0.0, 1.0)
		# Ease-out agar melambat saat mendekati posisi awal
		t = 1.0 - (1.0 - t) * (1.0 - t)
		var target := _posisi_saat_reset.lerp(_posisi_awal, t)
		move_and_collide(target - global_position)

		if _reset_elapsed >= _reset_dur:
			# Reset selesai — mulai gerakan baru
			_resetting  = false
			_bergerak   = true
			_elapsed    = 0.0
			_posisi_tujuan = _pending_tujuan
			_cycle_dur  = _posisi_awal.distance_to(_posisi_tujuan) / max(_pending_kecepatan, 1.0)
			if sfx_aktif != null:
				sfx_aktif.play()
		return

	if not _bergerak:
		return

	_elapsed += delta
	var phase := fmod(_elapsed, _cycle_dur * 2.0)
	var t     := phase / _cycle_dur
	if t > 1.0:
		t = 2.0 - t
	t = t * t * (3.0 - 2.0 * t)
	var target_pos := _posisi_awal.lerp(_posisi_tujuan, t)
	move_and_collide(target_pos - global_position)

# ─── World Change Handler ─────────────────────────────────────────────────────
func _on_quiz_solved(_variant_idx: int, world_changes: Array) -> void:
	for entry: WorldChangeEntry in world_changes:
		if entry.action != WorldChangeEntry.ActionType.MOVE_PLATFORM:
			continue
		if entry.platform_id != platform_id:
			continue

		# Hitung jarak — pakai dari entry jika diisi, fallback ke Inspector
		var j := entry.platform_jarak if entry.platform_jarak > 0.0 else jarak
		var k := entry.platform_kecepatan if entry.platform_kecepatan > 0.0 else kecepatan

		# Hitung posisi tujuan berdasarkan arah dan jarak
		var tujuan_baru := _posisi_awal
		match entry.platform_direction:
			0: tujuan_baru = _posisi_awal + Vector2(-j,  0)  # KIRI_KANAN
			1: tujuan_baru = _posisi_awal + Vector2( j,  0)  # KANAN_KIRI
			2: tujuan_baru = _posisi_awal + Vector2(0,  j)   # BAWAH_ATAS
			3: tujuan_baru = _posisi_awal + Vector2(0, -j)   # ATAS_BAWAH

		# Estimasi durasi reset agar kamera menunggu sampai platform selesai berubah arah
		var delay_kamera: float
		if _bergerak or _resetting:
			# Platform sedang bergerak → delay panjang agar player lihat animasi reset + arah baru
			var jarak_ke_awal  := global_position.distance_to(_posisi_awal)
			var jarak_total    := _posisi_awal.distance_to(_posisi_tujuan)
			var est_reset: float = _cycle_dur * clamp(jarak_ke_awal / max(jarak_total, 1.0), 0.1, 1.0)
			delay_kamera = est_reset + 2.5 #ANIMASI PLATFORM UBAH GERAKAN
		else:
			# Platform diam → delay pendek, animasi mulai bergerak cepat
			delay_kamera = 0.6  # ANIMASI PLATFORM BERGERAK

		CameraDirector.queue_cinematic(
			global_position,
			func(): _mulai_bergerak(tujuan_baru, k),
			Callable(),
			delay_kamera,
			self  # ← tambah: kamera mengikuti platform ini
		)
		break

## Mulai atau ubah arah gerakan platform.
## Platform selalu kembali ke posisi awal sebelum bergerak ke arah baru.
## Mulai atau ubah arah gerakan platform.
## jarak_baru dan kecepatan_baru: 0 = pakai nilai default dari Inspector.
func _mulai_bergerak(tujuan_baru: Vector2, kecepatan_baru: float) -> void:
	_pending_tujuan    = tujuan_baru
	_pending_kecepatan = kecepatan_baru

	if not _bergerak:
		# Platform diam — langsung mulai tanpa reset
		_bergerak      = true
		_elapsed       = 0.0
		_posisi_tujuan = tujuan_baru
		_cycle_dur     = _posisi_awal.distance_to(tujuan_baru) / max(kecepatan_baru, 1.0)
		if sfx_aktif != null:
			sfx_aktif.play()
	else:
		# Platform sedang bergerak — glide balik ke awal dulu
		_bergerak          = false
		_resetting         = true
		_reset_elapsed     = 0.0
		_posisi_saat_reset = global_position
		# Durasi reset proporsional dengan seberapa jauh dari posisi awal
		var jarak_ke_awal  := global_position.distance_to(_posisi_awal)
		var jarak_total    := _posisi_awal.distance_to(_posisi_tujuan)
		_reset_dur = _cycle_dur * clamp(jarak_ke_awal / max(jarak_total, 1.0), 0.1, 1.0)
