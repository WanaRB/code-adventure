extends Node

@onready var point_label: Label = %Point_Label
var points = 0

func add_point():
	points +=3
	prints(points)
	point_label.text = "Points = " + str(points)
