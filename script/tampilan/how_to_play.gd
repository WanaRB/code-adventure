extends Control

const C_DOT_AKT  := Color("#f9e2af")
const C_DOT_IDLE := Color("#45475a")

@onready var img_rect    : TextureRect = %ImgKartu
@onready var counter_lbl : Label       = %Counter
@onready var judul_lbl   : Label       = %JudulKartu
@onready var desc_lbl    : Label       = %Deskripsi
@onready var dot1        : ColorRect   = %Dot1
@onready var dot2        : ColorRect   = %Dot2
@onready var dot3        : ColorRect   = %Dot3
@onready var btn_prev    : Button      = %BtnPrev
@onready var btn_next    : Button      = %BtnNext

var _kartu_idx := 0
var _kartu_data := [
	{
		"judul": "Kontrol Karakter",
		"image": "res://assets/image/HowToPlay/kontrol.png",
		"desc":  "Gunakan [←] [→] untuk bergerak ke kiri dan kanan.\nTekan [Space] atau [↑] untuk melompat.\nDi HP, gunakan tombol kontrol yang muncul di layar."
	},
	{
		"judul": "Interaksi & Quiz",
		"image": "res://assets/image/HowToPlay/quiz.png",
		"desc":  "Dekati laptop lalu tekan [E] untuk membuka soal.\nKlik kata yang di-highlight, pilih jawaban, lalu tekan [Enter].\nJawab benar = poin bertambah. Jawab salah = nyawa berkurang!"
	},
	{
		"judul": "Cara Menyelesaikan Level",
		"image": "res://assets/image/HowToPlay/menang.png",
		"desc":  "Temukan semua laptop dan jawab soalnya.\nSetelah semua selesai, pintu akan terbuka.\nDekati pintu dan tekan [E] untuk menyelesaikan level."
	},
]

func _ready() -> void:
	_update_kartu()

func _update_kartu() -> void:
	var data: Dictionary = _kartu_data[_kartu_idx]
	if ResourceLoader.exists(data["image"]):
		img_rect.texture = load(data["image"])
	else:
		img_rect.texture = null
	counter_lbl.text = "%d / %d" % [_kartu_idx + 1, _kartu_data.size()]
	judul_lbl.text   = data["judul"]
	desc_lbl.text    = data["desc"]
	dot1.color = C_DOT_AKT if _kartu_idx == 0 else C_DOT_IDLE
	dot2.color = C_DOT_AKT if _kartu_idx == 1 else C_DOT_IDLE
	dot3.color = C_DOT_AKT if _kartu_idx == 2 else C_DOT_IDLE
	btn_prev.visible = _kartu_idx > 0
	btn_next.text = "Next →"
	btn_next.visible = _kartu_idx < _kartu_data.size() - 1

func _on_btn_prev_pressed() -> void:
	if _kartu_idx > 0:
		_kartu_idx -= 1
		_update_kartu()

func _on_btn_next_pressed() -> void:
	if _kartu_idx < _kartu_data.size() - 1:
		_kartu_idx += 1
		_update_kartu()
	else:
		_on_btn_kembali_pressed()

func _on_btn_kembali_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/main_menu.tscn")
