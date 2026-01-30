extends Node2D

@export var speed: float = 600.0 # Prędkość przesuwania kamery

func _process(delta):
	# Przesuwamy obiekt w prawo w każdej klatce
	position.x += speed * delta
