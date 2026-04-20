extends Node

@onready var point_label: Label = %Point_Label
# Ambil referensi ke container yang menampung 3 gambar darah
@onready var h_box_darah = %darah.get_node("HBoxContainer") 

var points = 0
var health = 3 

func _ready():
	GameEvents.player_hit.connect(_on_player_hit)
	update_ui()

# game_manager.gd

func add_point():
	points += 3
	print("Points saat ini: ", points)
	update_ui()
	
func _on_player_hit(amount):
	health -= amount
	update_ui()
	if health <= 0:
		panggil_layar_kalah()

func update_ui():
	# Update Poin
	if point_label:
		point_label.text = "Points = " + str(points)
	
	# Update Darah (Menyembunyikan/Menampilkan gambar)
	if h_box_darah:
		var list_darah = h_box_darah.get_children()
		for i in range(list_darah.size()):
			# Jika index i lebih kecil dari sisa health, gambar muncul
			# Contoh: health=2, maka index 0 dan 1 visible, index 2 hidden.
			list_darah[i].visible = i < health

func panggil_layar_kalah():
	get_tree().call_deferred("change_scene_to_file", "res://scenes/LoseScreen.tscn")
