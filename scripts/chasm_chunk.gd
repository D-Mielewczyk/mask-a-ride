extends Node2D

# --- KONFIGURACJA PRZEPAŚCI ---
@export_group("Ramp Settings")
@export var ramp_width: float = 600.0     # Długość rozbiegu
@export var landing_width: float = 600.0  # Długość lądowiska

@export_group("Random Gap Settings")
# Zamiast stałej wartości, definiujemy zakres losowania
@export var min_gap_width: float = 600.0  # Minimalna dziura
@export var max_gap_width: float = 1200.0 # Maksymalna dziura (trudna!)

@export_group("Random Drop Settings")
@export var min_drop_height: float = 100.0 # Minimalny uskok w dół
@export var max_drop_height: float = 600.0 # Maksymalny uskok (głęboki zjazd)
@export var tile_uv_scale: float = 0.08

# Punkt końcowy dla Managera Świata
var end_point_world: Vector2

func generate_terrain(start_pos: Vector2):
	position = Vector2(start_pos.x, 0)
	var start_y = start_pos.y
	
	# --- 1. LOSOWANIE WARTOŚCI DLA TEGO CHUNKA ---
	var current_gap_width = randf_range(min_gap_width, max_gap_width)
	var current_drop_height = randf_range(min_drop_height, max_drop_height)
	
	# (Opcjonalnie) Debugowanie w konsoli, żebyś widział co wylosowało
	# print("Przepaść: Gap=", current_gap_width, " Drop=", current_drop_height)

	# --- CZĘŚĆ 2: WYBICIE (RampBody) ---
	var curve_ramp = Curve2D.new()
	
	# Start (płaski, łączy się z poprzednim)
	curve_ramp.add_point(Vector2(0, start_y), Vector2.ZERO, Vector2(200, 0))
	
	# Koniec rampy (lekko w górę - wybicie)
	# Możesz tu też dodać losowość, np. różny kąt wybicia
	var ramp_end_y = start_y - 100 
	curve_ramp.add_point(Vector2(ramp_width, ramp_end_y), Vector2(-100, 0), Vector2.ZERO)
	
	build_island($RampBody, curve_ramp)
	
	# --- CZĘŚĆ 3: DZIURA (DeathZone) ---
	# Pozycjonujemy strefę śmierci na środku WYLOSOWANEJ szerokości
	$DeathZone.position = Vector2(ramp_width + (current_gap_width / 2), start_y + 1000)
	# Ważne: Skalujemy CollisionShape, żeby pasował do szerokości dziury?
	# Zazwyczaj wystarczy, że jest po prostu szeroki, ale można to poprawić:
	# $DeathZone/CollisionShape2D.shape.size.x = current_gap_width

	# --- CZĘŚĆ 4: LĄDOWANIE (LandingBody) ---
	var curve_landing = Curve2D.new()
	
	# Start lądowania:
	# X = koniec rampy + WYLOSOWANA DZIURA
	# Y = koniec rampy + WYLOSOWANY SPAD
	var land_start_x = ramp_width + current_gap_width
	var land_start_y = ramp_end_y + current_drop_height
	
	# Punkt przyziemienia (lekko wklęsły)
	curve_landing.add_point(Vector2(land_start_x, land_start_y), Vector2.ZERO, Vector2(200, 0))
	
	# Koniec chunka
	var land_end_x = land_start_x + landing_width
	var land_end_y = land_start_y 
	
	# Płaskie wyjście dla następnego chunka
	curve_landing.add_point(Vector2(land_end_x, land_end_y), Vector2(-200, 0), Vector2(100, 0))
	
	build_island($LandingBody, curve_landing)
	
	# Obliczamy punkt końcowy dla następnego chunka
	end_point_world = position + Vector2(land_end_x, land_end_y)

# Funkcja pomocnicza do budowania wyspy (bez zmian)
func build_island(body_node, curve: Curve2D):
	curve.bake_interval = 20.0
	var baked = curve.get_baked_points()
	var poly = PackedVector2Array(baked)
	
	var last_x = baked[-1].x
	var first_x = baked[0].x
	poly.append(Vector2(last_x, 2000))
	poly.append(Vector2(first_x, 2000))
	
	body_node.get_node("Polygon2D").polygon = poly
	body_node.get_node("CollisionPolygon2D").polygon = poly
	body_node.get_node("Line2D").points = baked
	
	var uv = PackedVector2Array()
	for p in poly:
		uv.append(p * tile_uv_scale)
	body_node.get_node("Polygon2D").uv = uv

func get_end_point():
	return end_point_world

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _ready():
	if $VisibleOnScreenNotifier2D:
		if not $VisibleOnScreenNotifier2D.screen_exited.is_connected(_on_screen_exited):
			$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)
			

func _on_screen_exited():

	# Chunk wyszedł całkowicie z ekranu -> usuwamy go z pamięci

	queue_free() 
