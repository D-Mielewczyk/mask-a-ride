extends RigidBody2D

signal died
var _is_dead := false
## --- PARAMETRY DO ULEPSZEŃ (Eksportowane do Inspektora) ---
@export_group("Animacja")
@export var max_animation_velocity = 300
@export var max_animation_speed = 2

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

var was_on_ground: bool = true 
@onready var jump_sound = $JumpSound
@onready var land_sound = $LandSound

var last_animation_was_not_slide = false

## --- ZMIENNE STANU ---
var current_fuel = 0.0
var coins: int = 2000
@onready var ray = $"rotating/RayCast2D"
@onready var gostek = $"rotating/gostek"
@onready var maska = $"rotating/maska"
var spawn_time
var SPAWN_PROTECTION_TIME: int = 2000
var death_timer: float = 0.0
const MAX_DANGER_TIME: float = 1.0 # czas po którym się umiera
@onready var rocket_foam: CPUParticles2D = $"rotating/RocketFoam"

@onready var death_sound1 = $Death1
@onready var detah_sound2 = $Death2

var current_animation = "idle"

func _ready():
	current_fuel = max_fuel # Startujemy z pełnym bakiem
	# Ustawiamy tarcie materiału na 0 w kodzie, żeby nic nie blokowało slajdu
	physics_material_override.friction = 0.0
	slide()
	last_animation_was_not_slide = false
	gostek.connect("animation_finished", animation_fin)
	spawn_time = Time.get_ticks_msec()
	_setup_rocket_foam()
	if GlobalSingleton.global != null:
		coins = GlobalSingleton.global.coins

func _physics_process(delta):
	if _is_dead:
		return
	if gostek != null:
		gostek.speed_scale = min(1, linear_velocity.x / max_animation_velocity) * max_animation_speed
	
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
		
		slide()
		
		# Skok
		if Input.is_action_just_pressed("ui_up"):
			jump()
			apply_central_impulse(n * 500.0) # Stała siła skoku

		# Prostowanie lub obracanie
		if rot_dir == 0:
			var target_angle = n.angle() + PI/2
			rotation = lerp_angle(rotation, target_angle, alignment_speed * delta)
			angular_velocity = lerp(angular_velocity, 0.0, 0.1)
		else:
			apply_torque(rot_dir * rotation_power)
		
		if not was_on_ground:
			land_sound.play()
			was_on_ground = true

	else:
		# --- LOGIKA W POWIETRZU ---
		linear_damp = air_damp
		
		if Input.is_action_pressed("ui_down"):
			apply_central_force(Vector2.DOWN * dive_force)
		
		if rot_dir != 0:
			apply_torque(rot_dir * rotation_power)
		if was_on_ground:
			jump()
			jump_sound.play( )
			was_on_ground = false
			
		if global_position.y > 2500:
			death()

	# --- SYSTEM RAKIETOWY (Działa zawsze po wciśnięciu Boosta) ---
	if is_boosting:
		# Pchamy postać w stronę, w którą jest aktualnie zwrócona
		var boost_dir = Vector2.RIGHT.rotated(rotation)
		apply_central_force(boost_dir * rocket_power)
		current_fuel -= fuel_consumption * delta
		
	if rocket_foam != null:
		rocket_foam.emitting = is_boosting
		
	if (linear_velocity.x < 30) and (Time.get_ticks_msec() - spawn_time > SPAWN_PROTECTION_TIME):
		death_timer += delta
	else:
		death_timer = 0
		
	if death_timer > MAX_DANGER_TIME:
		death()
		

# Funkcja do ulepszeń: tankowanie paliwa (np. po zebraniu znajdźki)
func add_fuel(amount):
	current_fuel = clamp(current_fuel + amount, 0, max_fuel)

func jump():
	gostek.play("jump")
	current_animation = "jump"

func breakk():
	gostek.play("break")
	current_animation = "break"

func slide():
	if current_animation == "idle":
		return
	gostek.play("idle")
	current_animation = "idle"

func death():
	if _is_dead:
		return
	_is_dead = true
	
	gostek.speed_scale = 1
	# --- POPRAWKA DŹWIĘKU ---
	# Ustawiamy dźwięki tak, by grały mimo pauzy gry
	death_sound1.process_mode = Node.PROCESS_MODE_ALWAYS
	detah_sound2.process_mode = Node.PROCESS_MODE_ALWAYS 
	
	print("ŚMIERĆ")
	gostek.play("death")
	maska.play("death")
	last_animation_was_not_slide = false
	
	collision_layer = 0
	collision_mask = 0
	freeze = true 
	
	get_tree().paused = true
	
	var death_height = global_position.y - 750 
	var fall_height = global_position.y + 5000 
	
	var jump_tween = create_tween()
	jump_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	var rot_tween = create_tween()
	rot_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# --- POPRAWKA OBROTU ---
	# Obracamy tylko grafikę (gostka), a nie cały węzeł 'self'. 
	# Dzięki temu tło podpięte pod pozycję gracza zostanie prosto.
	rot_tween.tween_property(gostek, "rotation_degrees", 360.0, 1.0)
	# Jeśli maska też ma się obracać:
	var maska_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	maska_tween.tween_property(maska, "rotation_degrees", 360.0, 1.0)
	
	jump_tween.tween_property(self, "global_position:y", death_height, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump_tween.tween_property(self, "global_position:y", fall_height, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	if randf() < 0.5:
		death_sound1.play()
	else:
		detah_sound2.play()
		
	jump_tween.finished.connect(func():
		get_tree().call_group("game_flow", "handle_player_death")
		
		var current = get_tree().current_scene
		if current != null and current.has_node("GameFlow"):
			var flow = current.get_node("GameFlow")
			if flow != null and flow.has_method("handle_player_death"):
				flow.handle_player_death()
	)
	

func animation_fin():
	if current_animation == "idle":
		return
	if current_animation == "break":
		return
	if current_animation == "flight":
		return
	if current_animation == "jump":
		gostek.play("flight")

func add_coins(amount: int) -> void:
	coins = max(0, coins + amount)
	if GlobalSingleton.global != null:
		GlobalSingleton.global.coins = coins


func revive() -> void:
	_is_dead = false
	slide()

func _on_death_area_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	death()

func _setup_rocket_foam() -> void:
	if rocket_foam == null:
		return
	if rocket_foam.texture != null:
		return
	var size := 8
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	rocket_foam.texture = ImageTexture.create_from_image(img)
