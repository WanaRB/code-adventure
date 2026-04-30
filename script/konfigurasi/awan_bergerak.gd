extends CanvasLayer

var _sudah_init := false  # cegah spawn ulang jika node di-reuse

# ─── KONFIGURASI TEKSTUR ──────────────────────────────────────────────────────
## Masukkan semua PNG awan di sini — tiap awan dipilih secara acak
@export var tekstur_awan: Array[Texture2D] = []

# ─── KONFIGURASI JUMLAH & GERAK ───────────────────────────────────────────────
## Jumlah awan yang muncul sekaligus
@export var jumlah_awan: int = 8

## Kecepatan gerak awan (pixel/detik). Positif = ke kanan, negatif = ke kiri
@export var kecepatan: float = 40.0

# ─── KONFIGURASI KETINGGIAN ───────────────────────────────────────────────────
## Batas atas awan dari tepi layar (pixel). 0 = paling atas layar
@export var ketinggian_atas: float = 30.0

## Batas bawah awan (pixel dari tepi atas layar). Awan tidak akan turun lebih dari ini
## Contoh: 300 = awan hanya muncul di 300px pertama dari atas layar
@export var ketinggian_bawah: float = 350.0

# ─── KONFIGURASI TAMPILAN ─────────────────────────────────────────────────────
## Skala terkecil awan (acak antara min dan max)
@export var skala_min: float = 0.4

## Skala terbesar awan
@export var skala_max: float = 0.9

## Opacity awan (0.0 = transparan penuh, 1.0 = solid)
@export var opacity: float = 0.7

## Panjang area awan (pixel). Samakan dengan panjang scene/map.
## 0 = otomatis pakai lebar viewport
@export var panjang_area: float = 0.0

# ─── Internal (jangan diubah) ─────────────────────────────────────────────────
var _awan: Array[Sprite2D] = []
var _kecepatan_tiap: Array[float] = []
var _vp_size: Vector2

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	if tekstur_awan.is_empty():
		push_warning("AwaanBergerak: tekstur_awan belum diisi!")
		return
	call_deferred("_init_awan")

func _init_awan() -> void:
	var tree := get_tree()
	var root := tree.root

	# Cek apakah sudah ada AwaanBergerak lain di root
	for node in root.get_children():
		if node == self:
			continue
		if node.is_in_group("awan_bergerak"):
			# Sudah ada — hapus instance ini, biarkan yang lama jalan
			queue_free()
			return

	# Belum ada — jadikan persistent di root
	add_to_group("awan_bergerak")
	if get_parent() != root:
		get_parent().remove_child(self)
		root.add_child(self)
		call_deferred("_mulai_spawn")
		return
	_mulai_spawn()

func _mulai_spawn() -> void:
	if _sudah_init:
		return
	_sudah_init = true

	_vp_size = get_viewport().get_visible_rect().size
	if panjang_area > 0.0:
		_vp_size.x = panjang_area
	if ketinggian_bawah <= ketinggian_atas:
		ketinggian_bawah = ketinggian_atas + 100.0

	_spawn_semua()
	get_tree().tree_changed.connect(_update_visibility)

func _spawn_semua() -> void:
	for i in jumlah_awan:
		var s := Sprite2D.new()

		# Pilih tekstur secara acak dari array
		s.texture = tekstur_awan[randi() % tekstur_awan.size()]
		s.modulate.a = opacity

		# Skala acak agar tidak terlihat seragam
		var sc := randf_range(skala_min, skala_max)
		s.scale = Vector2(sc, sc)

		# Bagi layar rata per slot, lalu tambah offset kecil agar tidak terlalu kaku
		var slot_width := _vp_size.x / jumlah_awan
		var offset_x := randf_range(-slot_width * 0.3, slot_width * 0.3)
		s.position = Vector2(
			slot_width * i + slot_width * 0.5 + offset_x,
			randf_range(ketinggian_atas, ketinggian_bawah)
		)

		# Kecepatan sedikit berbeda tiap awan agar tidak bergerak seragam
		var variasi := randf_range(0.6, 1.4)
		_kecepatan_tiap.append(kecepatan * variasi)

		add_child(s)
		_awan.append(s)

func _process(delta: float) -> void:
	# Margin sebelum awan di-wrap ke sisi lain (agar tidak pop tiba-tiba)
	var margin := 250.0

	for i in _awan.size():
		var s := _awan[i]
		s.position.x += _kecepatan_tiap[i] * delta

		if _kecepatan_tiap[i] > 0 and s.position.x > _vp_size.x + margin:
			s.position.x = -margin
			s.position.y = _cari_y_tidak_menggumpal(i)

		elif _kecepatan_tiap[i] < 0 and s.position.x < -margin:
			s.position.x = _vp_size.x + margin
			s.position.y = _cari_y_tidak_menggumpal(i)

## Cari posisi Y yang tidak terlalu dekat dengan awan lain di X yang sama.
func _cari_y_tidak_menggumpal(skip_index: int) -> float:
	var jarak_min := 150.0  # ubah angka ini: lebih besar = awan lebih renggang
	for _coba in range(10):  # coba maksimal 10x
		var y := randf_range(ketinggian_atas, ketinggian_bawah)
		var terlalu_dekat := false
		for j in _awan.size():
			if j == skip_index: continue
			if abs(_awan[j].position.y - y) < jarak_min:
				terlalu_dekat = true
				break
		if not terlalu_dekat:
			return y
	# Kalau tetap tidak ketemu, kembalikan Y acak biasa
	return randf_range(ketinggian_atas, ketinggian_bawah)

## Sembunyikan awan jika scene aktif bukan scene menu.
## Awan hanya tampil di main_menu, level_select, dan credits.
func _update_visibility() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var path := scene.scene_file_path
	var adalah_menu := (
		"main_menu" in path or
		"level_select" in path or
		"credits" in path
	)
	visible = adalah_menu
