extends Resource
class_name WorldChangeEntry

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                    DAFTAR AKSI PERUBAHAN DUNIA                             ║
# ║                                                                            ║
# ║  Cara menambah aksi baru:                                                  ║
# ║  1. Tambah nama aksi baru di enum ActionType di bawah                      ║
# ║  2. Tambah parameter aksi di bagian "Parameter Aksi" jika diperlukan       ║
# ║  3. Buat function handler di script node yang mau bereaksi                 ║
# ║  4. Hubungkan ke GameEvents.quiz_answered_correct di script tersebut       ║
# ║  5. Selesai! Aksi baru langsung bisa dipilih dari dropdown di Inspector    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

enum ActionType {
	## Membuka pintu tertentu. Isi juga "Door Id" di bawah.
	OPEN_DOOR      = 0,

	## Mengubah semua drone jahat (bisa_jadi_baik = true) menjadi baik.
	CONVERT_DRONES = 1,

	# ── Tambah aksi baru di sini ──────────────────────────────────────────────
	# Contoh:
	# SPAWN_PLATFORM  = 2,   # Memunculkan platform tersembunyi
	# UNLOCK_CHEST    = 3,   # Membuka peti harta
	# REMOVE_BARRIER  = 4,   # Menghilangkan penghalang/dinding
	# ─────────────────────────────────────────────────────────────────────────
}

## Pilih aksi yang akan terjadi ketika soal dijawab benar.
@export var action: ActionType = ActionType.OPEN_DOOR

# ─── Parameter Aksi ───────────────────────────────────────────────────────────
## [OPEN_DOOR] ID pintu yang akan dibuka. Cocokkan dengan 'door_id' di node pintu.
## Tidak berpengaruh untuk aksi selain OPEN_DOOR.
@export var door_id: int = 1

# Saat menambah aksi baru yang butuh parameter tambahan,
# tambahkan @export var di sini, contoh:
# @export var platform_id: int = 1     # untuk SPAWN_PLATFORM
# @export var chest_node_path: NodePath # untuk UNLOCK_CHEST
