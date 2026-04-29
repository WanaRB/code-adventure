extends Node

## Auto-request fullscreen di mobile web saat pertama kali user menyentuh layar.
## Node ini cukup di-autoload atau ditambahkan ke scene main_menu.

var _sudah_fullscreen := false

func _ready() -> void:
	# Hanya aktif di web mobile
	var is_mobile := OS.has_feature("web_android") or OS.has_feature("web_ios")
	if not is_mobile:
		queue_free()
		return
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if _sudah_fullscreen:
		return
	# Request fullscreen saat sentuhan pertama
	if event is InputEventScreenTouch and event.pressed:
		_sudah_fullscreen = true
		if OS.has_feature("web"):
			JavaScriptBridge.eval("""
				var el = document.documentElement;
				if (el.requestFullscreen) el.requestFullscreen();
				else if (el.webkitRequestFullscreen) el.webkitRequestFullscreen();
			""")
