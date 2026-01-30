extends RigidBody2D  # Musisz zmienić tę linię!

@export var rotation_power = 10000.0  # Siła obrotu

func _physics_process(delta):
# Pobieramy kierunek od gracza (-1 dla lewo, 1 dla prawo)
	var rotation_direction = Input.get_axis("ui_left", "ui_right")
	
	if rotation_direction != 0:
		# apply_torque dodaje siłę obrotową uwzględniającą masę obiektu
		apply_torque(rotation_direction * rotation_power)
