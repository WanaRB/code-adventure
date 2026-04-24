extends Camera2D

func _ready() -> void:
	CameraDirector.register_camera(self)  # ← harus "self", bukan $Camera2D
