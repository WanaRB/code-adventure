extends Area2D

## ID pintu ini. Di Inspector soal (.tres), buat WorldChangeEntry dengan:
##   Action = OPEN_DOOR
##   Door Id = (samakan dengan angka di sini)
@export var door_id: int = 1

@onready var sprite = $Sprite2D
@export_file("*.tscn") var target_level_path: String

var is_open := false
var player_di_dekat_pintu := false

func _ready():
	GameEvents.quiz_answered_correct.connect(_on_quiz_solved)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.frame = 1  # Mulai tertutup

# ── Handler World Change ────────────────────────────────────────────────────
func _on_quiz_solved(world_changes: Array):
	for entry: WorldChangeEntry in world_changes:
		# Pintu terbuka jika aksinya OPEN_DOOR dan door_id cocok
		if entry.action == WorldChangeEntry.ActionType.OPEN_DOOR and entry.door_id == door_id:
			_buka_pintu()

func _buka_pintu():
	if is_open:
		return
	is_open = true
	sprite.frame = 0  # Visual terbuka

# ── Interaksi Player ───────────────────────────────────────────────────────
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_di_dekat_pintu = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_di_dekat_pintu = false

func _input(event):
	if event.is_action_pressed("interact") and player_di_dekat_pintu and is_open:
		_pindah_level()

func _pindah_level():
	if target_level_path != "":
		get_tree().call_deferred("change_scene_to_file", target_level_path)
