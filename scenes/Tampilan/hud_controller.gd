extends CanvasLayer

func _ready():
	# Menghubungkan ke sinyal global
	GameEvents.quiz_opened.connect(_on_quiz_opened)
	GameEvents.quiz_closed.connect(_on_quiz_closed)

func _on_quiz_opened():
	# Karena skrip ini menempel di CanvasLayer, 'visible' sekarang berfungsi
	self.visible = false 

func _on_quiz_closed():
	self.visible = true
