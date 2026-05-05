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

# ─── Variasi Jawaban ──────────────────────────────────────────────────────────
## Tiap variant = 1 kombinasi jawaban + perubahan dunia yang dipicu.
## Cara isi di Inspector:
##   1. Klik [+] pada array "Variants"
##   2. Pilih "New QuizVariant"
##   3. Isi required_answers: key = index highlight (angka), value = teks jawaban
##   4. Isi world_changes seperti biasa
@export var variants: Array[QuizVariant] = []
