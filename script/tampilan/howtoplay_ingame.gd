extends Node

@onready var howtoplay_panel: Panel = %howtoplay_panel
@onready var img_rect: TextureRect    = %HTPImgKartu
@onready var counter_lbl: Label       = %HTPCounter
@onready var judul_lbl: Label         = %HTPJudulKartu
@onready var desc_lbl: Label          = %HTPDeskripsi
@onready var dot1: ColorRect          = %HTPDot1
@onready var dot2: ColorRect          = %HTPDot2
@onready var dot3: ColorRect          = %HTPDot3
@onready var btn_prev: Button         = %previous
@onready var btn_next: Button         = %next
@onready var btn_kembali: Button      = %kembali

const C_DOT_AKT  := Color("#f9e2af")
const C_DOT_IDLE := Color("#45475a")

var _dibuka_dari_pause := false
var _kartu_idx := 0
var _kartu_data := [
	{
		"judul": "Kontrol Karakter",
		"image": "res://assets/image/HowToPlay/kontrol.png",
		"desc":  "Gunakan [A] [D] atau [←] [→] untuk bergerak ke kiri dan ke kanan.\nTekan [A] atau [↑] untuk lompat.\nDi Mobile, gunakan tombol kontrol yang muncul di layar."
	},
	{
		"judul": "Laptop",
		"image": "res://assets/image/HowToPlay/laptop.png",
		"desc":  "Setiap level memiliki laptop yang tersebar di sekitar.\ninteraksi dengan laptop untuk membuka soal.\n"
	},
	{
		"judul": "Cara menjawab Soal",
		"image": "res://assets/image/HowToPlay/quiz.png",
		"desc":  "Klik kata yang di-highlight pada kode.\nPilih jawaban yang benar dari pilihan yang tersedia.\nTekan [Enter] untuk mengonfirmasi jawaban."
	},
	{
		"judul": "Perubahan Dunia",
		"image": "res://assets/image/HowToPlay/platform.png",
		"desc":  "Jawaban yang benar mengubah dunia disekitarmu.\nUbah soal untuk mengubah dunia yang akan membantu kamu menyelesaikan level"
	},
	{
		"judul": "Menangkan Level",
		"image": "res://assets/image/HowToPlay/menang.png",
		"desc":  "Masuk ke pintu untuk menyelesaikan level. Terkadang harus menyelesaikan soal dulu untuk membuka pintunya \n"
	},
]

func _ready() -> void:
	howtoplay_panel.hide()
	if not GameEvents.sudah_lihat_howtoplay:
		_tampilkan()
	add_to_group("howtoplay_ingame")
	btn_kembali.pressed.connect(_tutup)

func _tampilkan(dari_pause: bool = false) -> void:
	_dibuka_dari_pause = dari_pause
	_kartu_idx = 0
	_update_kartu()
	howtoplay_panel.show()
	get_tree().paused = true
	var mc := get_tree().get_first_node_in_group("mobile_controls")
	if mc: mc.visible = false

func _tutup() -> void:
	GameEvents.sudah_lihat_howtoplay = true
	SaveManager.save_to_file()
	howtoplay_panel.hide()
	if _dibuka_dari_pause:
		var pause_node := get_tree().get_first_node_in_group("pause_controller")
		if pause_node and pause_node.has_method("_on_pause_btn_pressed"):
			pause_node._on_pause_btn_pressed()
	else:
		get_tree().paused = false
	var mc := get_tree().get_first_node_in_group("mobile_controls")
	if mc: mc.visible = true

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
		_tutup()
