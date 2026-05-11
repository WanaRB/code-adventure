extends Control

# ─── KONFIGURASI ──────────────────────────────────────────────────────────────
## Gambar ikon suara hidup (megaphone on)
@export var ikon_suara_hidup: Texture2D
## Gambar ikon suara mati (megaphone off)
@export var ikon_suara_mati: Texture2D


# ─── Referensi Node ───────────────────────────────────────────────────────────
@onready var vbox: VBoxContainer = $VBoxContainer
@onready var logo: Node = $Logo
@onready var panel_options: Panel = $PanelOptions
@onready var check_fullscreen: OptionButton = $PanelOptions/VBoxContainer2/HBoxContainer2/CheckFullscreen
@onready var slider_musik: HSlider = $PanelOptions/VBoxContainer2/HBoxContainer/SliderMusik
# ─── State Internal ───────────────────────────────────────────────────────────
var _sudah_klik := false       # true setelah user klik splash screen
var _label_klik: Label = null  # referensi label "Klik to Play"
var _tween_kedip: Tween = null

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	var grabber := _buat_grabber(12, Color("#89b4fa"))
	slider_musik.add_theme_icon_override("grabber", grabber)
	slider_musik.add_theme_icon_override("grabber_highlight", _buat_grabber(13, Color("#cdd6f4")))
	slider_musik.custom_minimum_size.y = 30
	_setup_bgm()
	_setup_splash()
	#SaveManager.reset()  # ← tambah sementara, hapus setelah test
	panel_options.visible = false
	
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
		bgm.bus = $BgmMenu.bus  # ← salin bus "Music" dari node scene
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

# ─── Splash Screen ────────────────────────────────────────────────────────────
## Setup tampilan splash "Klik to Play" saat pertama kali buka game.
## Jika sudah pernah klik (misal balik dari credit/level select), langsung tampil tombol.
func _setup_splash() -> void:
	if GameEvents.sudah_lewat_splash:
		_animasi_masuk_dari_submenu()
		return

	# Sembunyikan tombol ke bawah layar
	vbox.modulate.a = 0.0
	vbox.position.y += 600.0
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ← nonaktifkan klik saat splash

	_munculkan_label_splash()

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
	if _tween_kedip:
		_tween_kedip.kill()
		_tween_kedip = null
	# Hilangkan label "Klik to Play"
	var tw_label := create_tween()
	tw_label.tween_property(_label_klik, "modulate:a", 0.0, 0.1)
	tw_label.tween_callback(_label_klik.queue_free)

	# Tombol naik dari bawah ke posisi asli
	# Ubah angka detik untuk mengatur kecepatan: lebih kecil = lebih cepat
	var tw_vbox := create_tween()
	tw_vbox.set_ease(Tween.EASE_OUT)
	tw_vbox.set_trans(Tween.TRANS_BACK)  # efek bouncy saat tiba
	tw_vbox.tween_property(vbox, "modulate:a", 1.0, 0.5)           # 0.4 = kecepatan fade in
	tw_vbox.parallel().tween_property(vbox, "position:y", vbox.position.y - 600.0, 0.7)  # 0.5 = kecepatan naik
	tw_vbox.tween_callback(func(): vbox.mouse_filter = Control.MOUSE_FILTER_STOP)  # ← tambah ini

# ─── Navigasi Tombol ──────────────────────────────────────────────────────────
func _on_button_main_pressed() -> void:
	_animasi_keluar("res://scenes/UI/play_menu.tscn")

func _on_button_settings_pressed() -> void:
	# Restore state dari GameEvents sebelum panel ditampilkan
	slider_musik.value = GameEvents.volume_musik
	var is_fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	GameEvents.is_fullscreen = is_fs
	check_fullscreen.set_block_signals(true)
	check_fullscreen.selected = 1 if is_fs else 0
	check_fullscreen.set_block_signals(false)
	vbox.visible = false
	panel_options.show()
	panel_options.mouse_filter = Control.MOUSE_FILTER_STOP
	
func _on_button_credit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/credits.tscn")

func _on_button_back_options_pressed() -> void:
	panel_options.visible = false
	vbox.visible = true

func _on_slider_musik_changed(value: float) -> void:
	GameEvents.volume_musik = value  # ← tambah ini
	var bus_idx := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value) if value > 0.0 else -80.0)

func _on_fullscreen_item_selected(index: int) -> void:
	print("fullscreen index: ", index)
	var toggled_on := index == 1
	GameEvents.is_fullscreen = toggled_on
	if OS.has_feature("web"):
		if toggled_on:
			JavaScriptBridge.eval("var el=document.documentElement;if(el.requestFullscreen)el.requestFullscreen();")
		else:
			JavaScriptBridge.eval("if(document.exitFullscreen)document.exitFullscreen();")
	else:
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on else DisplayServer.WINDOW_MODE_WINDOWED
		DisplayServer.window_set_mode(mode)
		
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
	# Tunggu animasi turun selesai, baru munculkan label
	tw.tween_callback(_munculkan_label_splash)

func _munculkan_label_splash() -> void:
	_label_klik = Label.new()
	_label_klik.text = "Tekan untuk Bermain"
	_label_klik.add_theme_font_size_override("font_size", 60)
	_label_klik.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_label_klik.set_anchors_preset(Control.PRESET_CENTER)
	_label_klik.custom_minimum_size = Vector2(600, 60)
	_label_klik.offset_left = -300.0
	_label_klik.offset_top  = -40.0
	_label_klik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label_klik)

	_tween_kedip = create_tween().set_loops()
	_tween_kedip.tween_property(_label_klik, "modulate:a", 0.1, 0.8)
	_tween_kedip.tween_property(_label_klik, "modulate:a", 1.0, 0.8)

func _animasi_keluar(target_scene: String) -> void:
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(vbox, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(vbox, "position:y", vbox.position.y + 600.0, 0.4)
	tw.tween_callback(func(): get_tree().change_scene_to_file(target_scene))

func _animasi_masuk_dari_submenu() -> void:
	vbox.modulate.a = 0.0
	vbox.position.y += 600.0
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.1)
	tw.tween_property(vbox, "modulate:a", 1.0, 0.5)
	tw.parallel().tween_property(vbox, "position:y", vbox.position.y - 600.0, 0.7)
	tw.tween_callback(func(): vbox.mouse_filter = Control.MOUSE_FILTER_STOP)

func _buat_grabber(radius: int, color: Color) -> ImageTexture:
	var size := radius * 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(radius, radius)
	for x in size:
		for y in size:
			if Vector2(x, y).distance_to(center) <= radius:
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)
