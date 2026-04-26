extends Camera2D

func _ready() -> void:
	# Script ini IS node Camera2D-nya, jadi pakai self, bukan $Camera2D
	CameraDirector.register_camera(self)
