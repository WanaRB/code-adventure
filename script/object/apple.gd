extends Area2D

@onready var sfx: AudioStreamPlayer = $AudioStreamPlayer

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Emit sinyal item_collected dengan nilai 10 poin
		GameEvents.item_collected.emit(10)
		sfx.play()
		visible = false
		set_deferred("monitoring", false)
		await sfx.finished
		queue_free()
