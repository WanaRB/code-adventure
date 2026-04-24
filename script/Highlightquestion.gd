extends Resource
class_name HighlightQuestion

## Satu kata yang bisa diklik di blok kode, beserta pilihan jawabannya.
## Buat beberapa HighlightQuestion di Inspector untuk soal dengan banyak highlight.

# Index baris kode (0 = baris pertama, 4 = baris kelima)
@export var line: int = 0

# Kata yang di-highlight kuning — HARUS sama persis dengan teks di code_lines[line]
@export var word: String = ""

# 3 pilihan jawaban yang muncul saat kata diklik
@export var options: Array[String] = ["", "", ""]

# Index jawaban benar (0, 1, atau 2)
@export var correct_index: int = 0
