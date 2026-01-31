extends Camera2D

# Eksportujemy zmienne, żeby widzieć je w Inspektorze po prawej
@export var target_node: RigidBody2D # Tu możesz przeciągnąć gracza w edytorze
@export var min_zoom = 0.5
@export var max_zoom = 0.25
@export var speed_threshold = 2000.0
@export var bg: Node2D
var bg_initial_scale = 0

func _ready() -> void:
	bg_initial_scale = bg.scale.x

func _physics_process(delta):
	# Jeśli nie przypisaliśmy noda w inspektorze, szukamy rodzica
	var target = target_node if target_node else get_parent() as RigidBody2D
	
	if target:
		var speed = target.linear_velocity.length()
		var target_z = remap(speed, 0, speed_threshold, min_zoom, max_zoom)
		target_z = clamp(target_z, max_zoom, min_zoom)
		
		# Wolny lerp (np. 1.5) = filmowe, płynne oddalanie
		# Szybki lerp (np. 5.0) = dynamiczne, agresywne oddalanie
		#zoom = zoom.lerp(Vector2(target_z, target_z), delta * 2.0)
		#if bg != null:
		#	bg.scale = Vector2(bg_initial_scale / scale.x, bg_initial_scale / scale.y)
