extends Node2D

@export var player: RigidBody2D
@export_range(0.01,0.05, 0.001) var speed_multiplier :float = 1
var proportions = []
var children : Array[Node]

func _ready() -> void:
	children = get_children()
	print(children)
	for child in children:
		proportions.append((child as Parallax2D).autoscroll.x)

func _process(delta) -> void:
	var v_x = player.linear_velocity.x as float
	global_rotation_degrees = 0
	var i = 0
	for child in children:
		(child as Parallax2D).autoscroll = Vector2((proportions[i] * v_x * speed_multiplier) as float, 0)
		# print("autoscroll.x: %f", (child as Parallax2D).autoscroll.x)
		i += 1
