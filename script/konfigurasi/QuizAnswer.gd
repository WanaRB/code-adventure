extends Resource
class_name QuizAnswer

## Index highlight yang dimaksud (0 = highlight pertama, 1 = kedua, dst).
@export var highlight_index: int = 0

## Teks jawaban yang diharapkan — harus sama persis dengan teks di options.
@export var teks: String = ""
