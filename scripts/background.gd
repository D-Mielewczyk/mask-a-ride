extends Node2D

@export var player: Player
@export_range(0.1,100, 0.1) var speed_multiplier :float = 1
var proportions = []
var children : Array[Node]

func _init() -> void:
	children = get_children()
	for child in children:
		proportions.append((child as Parallax2D).autoscroll.x)

func _ready() -> void:
	var v_x = player.velocity.x
	for child in children:
		(child as Parallax2D).autoscroll.x = proportions * v_x * global_scale
