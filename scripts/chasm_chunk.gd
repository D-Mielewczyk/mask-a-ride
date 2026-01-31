extends Node2D

# Konfiguracja Przepaści
@export var ramp_width: float = 600.0   # Długość rozbiegu
@export var gap_width: float = 800.0    # Szerokość dziury (jak daleko trzeba skoczyć)
@export var drop_height: float = 300.0  # O ile niżej jest lądowanie (ułatwia grę)
@export var landing_width: float = 600.0 # Długość lądowiska

# Punkt końcowy dla Managera Świata
var end_point_world: Vector2

func generate_terrain(start_pos: Vector2):
	position = Vector2(start_pos.x, 0) # Ustawiamy chunk w poziomie
	var start_y = start_pos.y
	
	# --- CZĘŚĆ 1: WYBICIE (RampBody) ---
	var curve_ramp = Curve2D.new()
	
	# Start (łączy się z poprzednim terenem)
	curve_ramp.add_point(Vector2(0, start_y), Vector2.ZERO, Vector2(200, 0))
	
	# Koniec rampy (lekko w górę, żeby wybić gracza)
	var ramp_end_y = start_y - 100 # Wybicie 100px w górę
	curve_ramp.add_point(Vector2(ramp_width, ramp_end_y), Vector2(-100, 0), Vector2.ZERO)
	
	build_island($RampBody, curve_ramp)
	
	# --- CZĘŚĆ 2: DZIURA (DeathZone) ---
	# Ustawiamy strefę śmierci idealnie w dziurze
	$DeathZone.position = Vector2(ramp_width + (gap_width / 2), start_y + 1000)
	# (Pamiętaj by ustawić CollisionShape w edytorze na odpowiednio duży!)

	# --- CZĘŚĆ 3: LĄDOWANIE (LandingBody) ---
	var curve_landing = Curve2D.new()
	
	# Start lądowania (Przesunięty o gap_width i niżej o drop_height)
	var land_start_x = ramp_width + gap_width
	var land_start_y = ramp_end_y + drop_height
	
	# Punkt przyziemienia (lekko wklęsły, żeby "złapać" gracza)
	curve_landing.add_point(Vector2(land_start_x, land_start_y), Vector2.ZERO, Vector2(200, 0))
	
	# Koniec chunka
	var land_end_x = land_start_x + landing_width
	var land_end_y = land_start_y # Płasko na końcu
	curve_landing.add_point(Vector2(land_end_x, land_end_y), Vector2(-200, 0), Vector2.ZERO)
	
	build_island($LandingBody, curve_landing)
	
	# Obliczamy punkt końcowy dla następnego chunka
	end_point_world = position + Vector2(land_end_x, land_end_y)

# Funkcja pomocnicza do budowania pojedynczej wyspy
func build_island(body_node, curve: Curve2D):
	curve.bake_interval = 20.0
	var baked = curve.get_baked_points()
	var poly = PackedVector2Array(baked)
	
	# Zamykanie kształtu do dołu
	var last_x = baked[-1].x
	var first_x = baked[0].x
	poly.append(Vector2(last_x, 2000)) # Prawy dół
	poly.append(Vector2(first_x, 2000)) # Lewy dół
	
	# Przypisywanie do węzłów wewnątrz body
	body_node.get_node("Polygon2D").polygon = poly
	body_node.get_node("CollisionPolygon2D").polygon = poly
	body_node.get_node("Line2D").points = baked
	
	# Opcjonalnie UV dla tekstury
	var uv = PackedVector2Array()
	for p in poly: uv.append(p / 100.0)
	body_node.get_node("Polygon2D").uv = uv

func get_end_point():
	return end_point_world

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
	
func _ready():
	# Połącz sygnał, jeśli nie zrobiłeś tego w edytorze
	# (Zakładając, że węzeł nazywa się VisibleOnScreenNotifier2D)
	$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)

func _on_screen_exited():
	# Chunk wyszedł całkowicie z ekranu -> usuwamy go z pamięci
	queue_free()
