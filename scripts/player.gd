extends RigidBody2D

## --- USTAWIENIA ALTO STYLE ---
@export_group("Ruch i Napęd")
@export var acceleration_scale = 1000.0  # Siła pchająca wzdłuż rampy
@export var sticky_force = 800.0        # Docisk do podłoża
@export var alignment_speed = 10.0      # Szybkość prostowania do kąta rampy

@export_group("Sterowanie Powietrzne")
@export var rotation_power = 20000.0     # Siła fikołków (Torque)
@export var air_damp = 0.2              # Opór powietrza w locie
@export var ground_damp = 0.0           # Opór na ziemi (0 = max pęd)

@onready var ray = $RayCast2D

func _ready():
	# Podstawowa konfiguracja fizyki w kodzie dla pewności
	can_sleep = false
	contact_monitor = true
	max_contacts_reported = 2
	# Ustawienie Continuous Collision Detection zapobiega wypadaniu z mapy
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE

func _physics_process(delta):
	var rotation_direction = Input.get_axis("ui_left", "ui_right")
	
	# Resetujemy siły stałe w każdej klatce, aby obliczyć je na nowo
	constant_force = Vector2.ZERO
	constant_torque = 0.0

	if ray.is_colliding():
		# --- LOGIKA NA ZIEMI ---
		linear_damp = ground_damp
		var n = ray.get_collision_normal()
		
		# 1. Docisk prostopadły do rampy
		apply_central_force(-n * sticky_force)
		
		# 2. Napęd wzdłuż rampy (Tangent)
		# Obracamy normalną o 90 stopni, by uzyskać kierunek ruchu (w prawo)
		var slope_dir = n.rotated(PI/2)
		
		# Jeśli jedziemy w prawo, upewniamy się że wektor pcha w prawo
		if slope_dir.x < 0:
			slope_dir = -slope_dir
		
		# Aplikujemy siłę napędową (im bardziej stromo w dół, tym x jest większe)
		# Mnożymy przez slope_dir.x aby postać nie przyspieszała pod górę tak samo jak w dół
		if slope_dir.x > 0.1:
			apply_central_force(slope_dir * acceleration_scale)
		
		# 3. Automatyczne prostowanie do rampy
		if rotation_direction == 0:
			var target_angle = n.angle() + PI/2
			rotation = lerp_angle(rotation, target_angle, alignment_speed * delta)
			angular_velocity = lerp(angular_velocity, 0.0, 0.1)

	else:
		# --- LOGIKA W POWIETRZU ---
		linear_damp = air_damp
		
		if rotation_direction != 0:
			apply_torque(rotation_direction * rotation_power)
