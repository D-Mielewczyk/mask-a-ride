extends RigidBody2D

## --- PARAMETRY DO ULEPSZEŃ (Eksportowane do Inspektora) ---
@export_group("Ruch i Slidowanie")
@export var acceleration_scale = 4000.0  # Jak mocno pcha w dół (Alto style)
@export var ground_damp = 0.05           # Im mniejszy, tym lepszy poślizg na ziemi
@export var sticky_force = 300.0         # Siła docisku (magnes)
						  
@export_group("Powietrze i Zwrotność")
@export var air_damp = 0.1               # Opór powietrza (im mniej, tym dalej lecisz)
@export var rotation_power = 15000.0     # ZWROTNOŚĆ: Siła obracania fikołków
@export var dive_force = 1800.0          # Jak szybko nurkujesz w dół
@export var alignment_speed = 12.0       # Jak szybko postać prostuje się do rampy

@export_group("Rakieta (Boost)")
@export var rocket_power = 2000.0       # Siła kopa rakiety
@export var max_fuel = 100.0             # Maksymalne paliwo
@export var fuel_consumption = 40.0      # Zużycie paliwa na sekundę

## --- ZMIENNE STANU ---
var current_fuel = 0.0
@onready var ray = $RayCast2D

func _ready():
	current_fuel = max_fuel # Startujemy z pełnym bakiem
	# Ustawiamy tarcie materiału na 0 w kodzie, żeby nic nie blokowało slajdu
	physics_material_override.friction = 0.0

func _physics_process(delta):
	var rot_dir = Input.get_axis("ui_left", "ui_right")
	var is_boosting = Input.is_action_pressed("ui_accept") and current_fuel > 0 # np. Spacja

	# Reset sił stałych
	constant_force = Vector2.ZERO

	if ray.is_colliding():
		# --- LOGIKA NA ZIEMI ---
		linear_damp = ground_damp
		var n = ray.get_collision_normal()
		
		# Docisk (tylko gdy lekko odrywamy się od ziemi)
		if global_position.distance_to(ray.get_collision_point()) > 20:
			apply_central_force(-n * sticky_force)
		
		# Napęd w dół rampy (Tangent)
		var slope_dir = n.rotated(PI/2)
		if slope_dir.x < 0: slope_dir = -slope_dir
		
		if n.x > 0.05: # Zjazd
			apply_central_force(slope_dir * acceleration_scale * n.x)
		
		# Skok
		if Input.is_action_just_pressed("ui_up"):
			apply_central_impulse(n * 500.0) # Stała siła skoku

		# Prostowanie lub obracanie
		if rot_dir == 0:
			var target_angle = n.angle() + PI/2
			rotation = lerp_angle(rotation, target_angle, alignment_speed * delta)
			angular_velocity = lerp(angular_velocity, 0.0, 0.1)
		else:
			apply_torque(rot_dir * rotation_power)

	else:
		# --- LOGIKA W POWIETRZU ---
		linear_damp = air_damp
		
		if Input.is_action_pressed("ui_down"):
			apply_central_force(Vector2.DOWN * dive_force)
		
		if rot_dir != 0:
			apply_torque(rot_dir * rotation_power)

	# --- SYSTEM RAKIETOWY (Działa zawsze po wciśnięciu Boosta) ---
	if is_boosting:
		# Pchamy postać w stronę, w którą jest aktualnie zwrócona
		var boost_dir = Vector2.RIGHT.rotated(rotation)
		apply_central_force(boost_dir * rocket_power)
		current_fuel -= fuel_consumption * delta
		print("Paliwo: ", int(current_fuel)) # Debug w konsoli

# Funkcja do ulepszeń: tankowanie paliwa (np. po zebraniu znajdźki)
func add_fuel(amount):
	current_fuel = clamp(current_fuel + amount, 0, max_fuel)
