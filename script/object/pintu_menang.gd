extends Area2D

@export var door_id: int = 1
@export var terbuka_dari_awal: bool = false
@export var sfx_buka: AudioStreamPlayer2D
@onready var sprite = $Sprite2D

## Path tujuan. Untuk level 1 & 2 biarkan kosong atau isi menang.tscn.
## Script ini SELALU mengarah ke menang.tscn untuk level 1-3.
## Ubah ke false hanya jika ingin skip winscreen dan langsung ke scene lain.
@export var pakai_winscreen: bool = true
@export_file("*.tscn") var target_level_path: String

var is_open := false
var player_di_dekat_pintu := false
var _label_interaksi: Node2D = null

func _ready():
	GameEvents.quiz_answered_correct.connect(_on_quiz_solved)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if terbuka_dari_awal:
		is_open = true
		sprite.frame = 0
	else:
		sprite.frame = 1
	_buat_label_interaksi()

func _on_quiz_solved(_variant_idx: int, world_changes: Array):
	for entry: WorldChangeEntry in world_changes:
		if entry.action == WorldChangeEntry.ActionType.OPEN_DOOR and entry.door_id == door_id:
			CameraDirector.queue_cinematic(global_position, _buka_pintu, Callable(), 0.6)
			break

func _buka_pintu():
	if is_open: return
	is_open = true
	sprite.frame = 0
	if sfx_buka != null: sfx_buka.play()
	if _label_interaksi and player_di_dekat_pintu:
		_label_interaksi.visible = true

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_di_dekat_pintu = true
		if _label_interaksi and is_open:
			_label_interaksi.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_di_dekat_pintu = false
		if _label_interaksi:
			_label_interaksi.visible = false
			
func _input(event):
	if event.is_action_pressed("interact") and player_di_dekat_pintu and is_open:
		_pindah_level()

func _pindah_level():
	var current: int = _nomor_level_dari_path(GameEvents.last_level_path)

	# Unlock level berikutnya
	if current > 0 and current < 5:
		SaveManager.unlock_level(current + 1)

	# Simpan stats sebelum pindah scene
	GameEvents.level_won.emit()

	# FIX: Jika pakai_winscreen = true (default), SELALU ke menang.tscn
	# Ini mengatasi masalah target_level_path yang masih menunjuk ke level berikutnya
	if pakai_winscreen:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/UI/menang.tscn")
	elif target_level_path != "":
		get_tree().call_deferred("change_scene_to_file", target_level_path)

func _nomor_level_dari_path(path: String) -> int:
	if "level_1" in path: return 1
	if "level_2" in path: return 2
	if "level_3" in path: return 3
	if "level_4" in path: return 4  
	if "level_5" in path: return 5 
	if "level_6" in path: return 6
	return 0

func _buat_label_interaksi() -> void:
	var container := Node2D.new()
	container.position = Vector2(0, -90)
	container.visible = false
	add_child(container)
	_label_interaksi = container

	var label := Label.new()
	label.text = "Tekan [E] untuk interaksi"
	label.add_theme_font_size_override("font_size", 25)
	label.add_theme_color_override("font_color", Color("ffffffff"))
	label.add_theme_color_override("font_outline_color", Color("000000ff"))
	label.add_theme_constant_override("outline_size", 4)
	label.position = Vector2(-130, -10)
	container.add_child(label)
