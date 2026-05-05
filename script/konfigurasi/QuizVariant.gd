extends Resource
class_name QuizVariant

## Daftar jawaban yang harus dipenuhi untuk variant ini.
## Tambah item → New QuizAnswer → isi highlight_index dan teks.
@export var required_answers: Array[QuizAnswer] = []

## Perubahan dunia yang terjadi jika kombinasi jawaban ini terpenuhi.
@export var world_changes: Array[WorldChangeEntry] = []
