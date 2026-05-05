extends Resource
class_name WorldChangeEntry

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                    DAFTAR AKSI PERUBAHAN DUNIA                             ║
# ║                                                                            ║
# ║  Cara menambah aksi baru:                                                  ║
# ║  1. Tambah nama aksi baru di enum ActionType di bawah                      ║
# ║  2. Tambah parameter aksi jika perlu di bagian "Parameter Aksi"            ║
# ║  3. Buat function handler di script node yang mau bereaksi                 ║
# ║  4. Hubungkan ke GameEvents.quiz_answered_correct di script tersebut       ║
# ║  5. Selesai! Aksi baru langsung bisa dipilih dari dropdown di Inspector    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

enum ActionType {
	## Membuka pintu tertentu. Isi juga "Door Id" di bawah.
	OPEN_DOOR      = 0,

	## Mengubah semua drone jahat (bisa_jadi_baik = true) menjadi baik.
	CONVERT_DRONES = 1,

	## Menggerakkan platform berdasarkan Platform Id.
	## Isi juga "Platform Id" di bawah. Platform harus punya script platform_bergerak.gd.
	MOVE_PLATFORM  = 2,

	# ── Tambah aksi baru di sini ──────────────────────────────────────────────
}

## [MOVE_PLATFORM] Jarak pergerakan (pixel). 0 = pakai nilai default di Inspector platform.
@export var platform_jarak: float = 0.0

## [MOVE_PLATFORM] Kecepatan pergerakan (pixel/detik). 0 = pakai nilai default di Inspector platform.
@export var platform_kecepatan: float = 0.0

## Pilih aksi yang akan terjadi ketika soal dijawab benar.
@export var action: ActionType = ActionType.OPEN_DOOR

# ─── Parameter Aksi ───────────────────────────────────────────────────────────
## [OPEN_DOOR] ID pintu yang akan dibuka. Cocokkan dengan 'door_id' di node pintu.
@export var door_id: int = 1

## [MOVE_PLATFORM] ID platform yang akan digerakkan. Cocokkan dengan 'platform_id'.
@export var platform_id: int = 1

## [MOVE_PLATFORM] Arah gerakan platform.
## 0 = Kiri-Kanan, 1 = Kanan-Kiri, 2 = Bawah-Atas, 3 = Atas-Bawah
@export var platform_direction: int = 0
