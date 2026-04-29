extends Node2D

@export_group("Awan")
@export var tekstur_awan: Array[Texture2D] = []
@export_range(1, 50, 1) var jumlah_awan: int = 6
@export_range(-300.0, 300.0, 1.0) var kecepatan: float = 40.0

@export_group("Tampilan")
@export_range(0.1, 3.0, 0.1) var skala_min: float = 0.4
@export_range(0.1, 3.0, 0.1) var skala_max: float = 0.9
@export_range(0.0, 1.0, 0.01) var opacity: float = 0.7

@export_group("Ketinggian")
@export_range(-200.0, 2000.0, 1.0) var y_min: float = 50.0
@export_range(-200.0, 2000.0, 1.0) var y_max: float = 250.0

@export_group("Wrap")
@export_range(0.0, 1000.0, 1.0) var margin_wrap: float = 200.0

var _awan: Array[Sprite2D] = []
var _kecepatan_tiap: Array[float] = []
var _vp_size: Vector2

func _ready() -> void:

	if tekstur_awan.is_empty():
		push_warning("tekstur_awan belum diisi!")
		return

	_vp_size = get_viewport().get_visible_rect().size
	_spawn_semua()

func _spawn_semua() -> void:
	for i in jumlah_awan:
		var s := Sprite2D.new()

		s.texture = tekstur_awan[randi() % tekstur_awan.size()]
		s.modulate.a = opacity

		var sc := randf_range(skala_min, skala_max)
		s.scale = Vector2(sc, sc)

		s.position = Vector2(
			randf_range(0, _vp_size.x),
			randf_range(minf(y_min, y_max), maxf(y_min, y_max))
		)

		var variasi := randf_range(0.6, 1.4)
		_kecepatan_tiap.append(kecepatan * variasi)

		add_child(s)
		_awan.append(s)

func _process(delta: float) -> void:
	for i in _awan.size():
		var s := _awan[i]
		s.position.x += _kecepatan_tiap[i] * delta

		if _kecepatan_tiap[i] > 0 and s.position.x > _vp_size.x + margin_wrap:
			s.position.x = -margin_wrap
			s.position.y = randf_range(minf(y_min, y_max), maxf(y_min, y_max))
		elif _kecepatan_tiap[i] < 0 and s.position.x < -margin_wrap:
			s.position.x = _vp_size.x + margin_wrap
			s.position.y = randf_range(minf(y_min, y_max), maxf(y_min, y_max))
