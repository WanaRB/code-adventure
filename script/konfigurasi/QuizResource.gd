extends Resource
class_name QuizResource

# ─── Blok Kode ────────────────────────────────────────────────────────────────
## 5 baris kode yang ditampilkan di editor.
## Gunakan "" untuk baris kosong.
@export var code_lines: Array[String] = [
	"# Kode baris 1",
	"# Kode baris 2",
	"# Kode baris 3",
	"# Kode baris 4",
	"# Kode baris 5"
]

# ─── Highlight ────────────────────────────────────────────────────────────────
## Daftar kata yang bisa diklik di dalam blok kode.
## Tiap item adalah resource HighlightQuestion.
## Cara isi di Inspector:
##   1. Klik tanda [+] pada array "Highlights"
##   2. Pilih "New HighlightQuestion"
##   3. Isi: line (index baris 0-4), word (kata yang di-highlight),
##      options (3 pilihan jawaban), correct_index (0/1/2)
@export var highlights: Array[HighlightQuestion] = []

# ─── Perubahan Dunia ──────────────────────────────────────────────────────────
## Aksi yang dijalankan ketika SEMUA highlight dijawab benar.
## Cara isi di Inspector:
##   1. Klik tanda [+] pada array "World Changes"
##   2. Pilih "New WorldChangeEntry"
##   3. Pilih "Action" dari dropdown (OPEN_DOOR, CONVERT_DRONES, dll)
##   4. Isi parameter tambahan jika perlu (misal Door Id untuk OPEN_DOOR)
##   5. Tambah lebih dari 1 entry untuk efek berganda
@export var world_changes: Array[WorldChangeEntry] = []
