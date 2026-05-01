extends Control

# ─── KONFIGURASI ──────────────────────────────────────────────────────────────
## Gambar ikon suara hidup (megaphone on)
@export var ikon_suara_hidup: Texture2D
## Gambar ikon suara mati (megaphone off)
@export var ikon_suara_mati: Texture2D

# ─── Referensi Node ───────────────────────────────────────────────────────────
@onready var vbox: VBoxContainer = $VBoxContainer
@onready var logo: Node = $Logo

# ─── State Internal ───────────────────────────────────────────────────────────
var _sudah_klik := false       # true setelah user klik splash screen
var _label_klik: Label = null  # referensi label "Klik to Play"

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	_setup_bgm()
	_tambah_tombol_suara()
	_setup_splash()

# ─── BGM ──────────────────────────────────────────────────────────────────────
## Buat node BgmMenu persistent di root agar musik tidak restart saat ganti scene.
func _setup_bgm() -> void:
	var existing := get_tree().root.get_node_or_null("BgmMenu")
	if existing == null:
		# Pertama kali: pindahkan ke root sebagai node baru
		var bgm := AudioStreamPlayer.new()
		bgm.name = "BgmMenu"
		bgm.stream = $BgmMenu.stream
		bgm.volume_db = $BgmMenu.volume_db
		$BgmMenu.queue_free()
		get_tree().root.call_deferred("add_child", bgm)
		bgm.call_deferred("play")
	else:
		# Sudah ada: hapus duplikat dari scene ini, sinkronkan state
		if has_node("BgmMenu"):
			$BgmMenu.queue_free()
		if GameEvents.musik_menu_hidup and not existing.playing:
			existing.play()
		elif not GameEvents.musik_menu_hidup:
			existing.stop()

## Hentikan musik menu (dipanggil sebelum masuk ke level).
func _stop_bgm() -> void:
	var bgm := get_tree().root.get_node_or_null("BgmMenu")
	if bgm:
		bgm.stop()

# ─── Tombol Suara ─────────────────────────────────────────────────────────────
## Tambahkan tombol mute/unmute di pojok kanan bawah.
func _tambah_tombol_suara() -> void:
	var btn := TextureButton.new()
	btn.name = "TombolSuara"

	# Sesuaikan ikon dengan state saat ini
	var ikon := ikon_suara_hidup if GameEvents.musik_menu_hidup else ikon_suara_mati
	btn.texture_normal  = ikon
	btn.texture_pressed = ikon
	btn.texture_hover   = ikon
	btn.ignore_texture_size = true
	btn.custom_minimum_size = Vector2(80, 80)
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Posisi pojok kanan bawah — sesuaikan offset jika perlu
	btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn.offset_left   = -120.0
	btn.offset_top    = -150.0
	btn.offset_right  = -40.0
	btn.offset_bottom = -70.0

	btn.pressed.connect(func(): _toggle_suara(btn))
	add_child(btn)

## Toggle musik hidup/mati dan update ikon tombol.
func _toggle_suara(btn: TextureButton) -> void:
	GameEvents.musik_menu_hidup = not GameEvents.musik_menu_hidup
	var bgm := get_tree().root.get_node_or_null("BgmMenu")
	if GameEvents.musik_menu_hidup:
		if bgm: bgm.play()
		btn.texture_normal  = ikon_suara_hidup
		btn.texture_pressed = ikon_suara_hidup
		btn.texture_hover   = ikon_suara_hidup
	else:
		if bgm: bgm.stop()
		btn.texture_normal  = ikon_suara_mati
		btn.texture_pressed = ikon_suara_mati
		btn.texture_hover   = ikon_suara_mati

# ─── Splash Screen ────────────────────────────────────────────────────────────
## Setup tampilan splash "Klik to Play" saat pertama kali buka game.
## Jika sudah pernah klik (misal balik dari credit/level select), langsung tampil tombol.
func _setup_splash() -> void:
	if GameEvents.sudah_lewat_splash:
		return

	# Sembunyikan tombol ke bawah layar
	vbox.modulate.a = 0.0
	vbox.position.y += 600.0

	# Label "Klik to Play" berkedip di tengah
	_label_klik = Label.new()
	_label_klik.text = "Tekan untuk Bermain"
	_label_klik.add_theme_font_size_override("font_size", 60)
	_label_klik.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_label_klik.set_anchors_preset(Control.PRESET_CENTER)
	_label_klik.custom_minimum_size = Vector2(600, 60)  # lebar cukup agar teks tidak terpotong
	_label_klik.offset_left = -300.0  # setengah dari lebar agar benar-benar tengah
	_label_klik.offset_top  = -40.0    # geser ke bawah dari tengah — ubah angka ini untuk naik/turun
	_label_klik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER # geser ke bawah logo — sesuaikan jika perlu
	add_child(_label_klik)

	# Animasi kedip
	var tween := create_tween().set_loops()
	tween.tween_property(_label_klik, "modulate:a", 0.1, 1)
	tween.tween_property(_label_klik, "modulate:a", 1.0, 1)

## Deteksi klik pertama untuk memulai animasi masuk tombol.
func _input(event: InputEvent) -> void:
	if _sudah_klik:
		return
	if GameEvents.sudah_lewat_splash:
		return
	var is_klik: bool = (
		event is InputEventMouseButton and event.pressed or
		event is InputEventScreenTouch and event.pressed
	)
	if not is_klik:
		return
	_sudah_klik = true
	_animasi_masuk()

## Animasi tombol naik dari bawah ke posisi normal setelah splash diklik.
func _animasi_masuk() -> void:
	GameEvents.sudah_lewat_splash = true

	# Hilangkan label "Klik to Play"
	var tw_label := create_tween()
	tw_label.tween_property(_label_klik, "modulate:a", 0.0, 0.3)
	tw_label.tween_callback(_label_klik.queue_free)

	# Tombol naik dari bawah ke posisi asli
	# Ubah angka detik untuk mengatur kecepatan: lebih kecil = lebih cepat
	var tw_vbox := create_tween()
	tw_vbox.set_ease(Tween.EASE_OUT)
	tw_vbox.set_trans(Tween.TRANS_BACK)  # efek bouncy saat tiba
	tw_vbox.tween_property(vbox, "modulate:a", 1.0, 0.4)           # 0.4 = kecepatan fade in
	tw_vbox.parallel().tween_property(vbox, "position:y", vbox.position.y - 600.0, 0.5)  # 0.5 = kecepatan naik

# ─── Navigasi Tombol ──────────────────────────────────────────────────────────
func _on_button_start_pressed() -> void:
	_stop_bgm()
	get_tree().change_scene_to_file("res://scenes/Level/level_1.tscn")

func _on_button_level_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/level_select.tscn")

func _on_button_credit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/credits.tscn")

## Tombol exit: kembali ke splash screen dengan animasi tombol turun.
func _on_button_exit_pressed() -> void:
	GameEvents.sudah_lewat_splash = false
	_sudah_klik = false

	# Animasi tombol turun ke bawah layar
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(vbox, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(vbox, "position:y", vbox.position.y + 600.0, 0.4)

	# Munculkan kembali label "Klik to Play"
	_label_klik = Label.new()
	_label_klik.text = "Tekan untuk Bermain"
	_label_klik.add_theme_font_size_override("font_size", 60)
	_label_klik.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_label_klik.set_anchors_preset(Control.PRESET_CENTER)
	_label_klik.custom_minimum_size = Vector2(600, 60)  # lebar cukup agar teks tidak terpotong
	_label_klik.offset_left = -300.0  # setengah dari lebar agar benar-benar tengah
	_label_klik.offset_top  = -40.0    # geser ke bawah dari tengah — ubah angka ini untuk naik/turun
	_label_klik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label_klik)

	var tw_label := create_tween().set_loops()
	tw_label.tween_property(_label_klik, "modulate:a", 0.1, 0.8)
	tw_label.tween_property(_label_klik, "modulate:a", 1.0, 0.8)
