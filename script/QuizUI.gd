extends CanvasLayer

@onready var label_soal = $Panel/MarginContainer/VBoxContainer/soal_Label
@onready var spacer = $Panel/MarginContainer/VBoxContainer/spacer
@onready var tombol_0 = $Panel/MarginContainer/VBoxContainer/Option0
@onready var tombol_1 = $Panel/MarginContainer/VBoxContainer/Option1
@onready var tombol_2 = $Panel/MarginContainer/VBoxContainer/Option2

var correct_index: int = 0

func setup_quiz(data: QuizResource):
	label_soal.text = data.question
	tombol_0.text = data.options[0]
	tombol_1.text = data.options[1]
	tombol_2.text = data.options[2]
	correct_index = data.correct_index

func _on_option_pressed(index: int):
	if index == correct_index:
		print("Jawaban Benar! Memicu perubahan dunia...")
	else:
		print("Jawaban Salah! HP berkurang.")
	
	tutup_kuis()
	

func _on_close_button_pressed():
	tutup_kuis()

func tutup_kuis():
	# Kirim sinyal agar HUD tahu kuis sudah selesai
	GameEvents.quiz_closed.emit() 
	
	get_tree().paused = false
	queue_free()
