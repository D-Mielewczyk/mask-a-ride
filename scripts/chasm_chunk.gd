extends Node2D

# --- KONFIGURACJA PRZEPAŚCI ---
@export_group("Ramp Settings")
@export var ramp_width: float = 1000.0     # Długość rozbiegu
@export var landing_width: float = 1000.0  # Długość lądowiska

@export_group("Random Gap Settings")
# Zamiast stałej wartości, definiujemy zakres losowania
@export var min_gap_width: float = 600.0  # Minimalna dziura
@export var max_gap_width: float = 1200.0 # Maksymalna dziura (trudna!)

@export_group("Random Drop Settings")
@export var min_drop_height: float = 200.0 # Minimalny uskok w dół
@export var max_drop_height: float = 700.0 # Maksymalny uskok (głęboki zjazd)
@export var tile_uv_scale: float = 0.08

# Punkt końcowy dla Managera Świata
var end_point_world: Vector2

func generate_terrain(start_pos: Vector2):
	position = Vector2(start_pos.x, 0)
	var start_y = start_pos.y
	
	# 1. Losowanie (bez zmian)
	var current_gap_width = randf_range(min_gap_width, max_gap_width)
	var current_drop_height = randf_range(min_drop_height, max_drop_height)

	# --- CZĘŚĆ 2: WYBICIE (RAMPA - Delikatna) ---
	var curve_ramp = Curve2D.new()
	
	# Start (Płasko)
	# Dajemy dłuższą rączkę wyjściową (400, 0), żeby teren długo pozostawał płaski
	curve_ramp.add_point(Vector2(0, start_y), Vector2.ZERO, Vector2(ramp_width * 0.5, 0))
	
	# Koniec (Wyskok)
	# Zmniejszamy wysokość wybicia (np. 60-80px zamiast 100), jest subtelniej.
	var ramp_rise = 80.0 
	var ramp_end_y = start_y - ramp_rise 
	
	# KLUCZ DO SUKCESU: Rączka wejściowa (in_vec)
	# Vector2(-ramp_width * 0.8, 0) -> Długa rączka sprawia, że wznoszenie zaczyna się
	# bardzo późno i jest bardzo gładkie (kształt litery J, ale rozciągniętej).
	curve_ramp.add_point(Vector2(ramp_width, ramp_end_y), Vector2(-ramp_width * 0.8, 0), Vector2.ZERO)
	
	build_island($RampBody, curve_ramp)
	
	# --- CZĘŚĆ 3: DZIURA (DeathZone - bez zmian) ---
	$DeathZone.position = Vector2(ramp_width + (current_gap_width / 2), start_y + 1000)

# --- CZĘŚĆ 4: LĄDOWANIE (NAPRAWIONE) ---
	var curve_landing = Curve2D.new()
	
	var land_start_x = ramp_width + current_gap_width
	var land_start_y = ramp_end_y + current_drop_height
	
	var land_end_x = land_start_x + landing_width
	# Opcjonalnie: Lądowisko może jeszcze trochę opadać w trakcie jazdy (np. +50px w dół)
	var land_end_y = land_start_y + 50.0 
	
	# Obliczamy różnicę wysokości i szerokości lądowania
	var diff_x = land_end_x - land_start_x
	var diff_y = land_end_y - land_start_y
	
# PUNKT 1: SZCZYT LĄDOWANIA
	# out_vec: Ciągnie w prawo i w dół.
	# Ustawiamy go na 50% szerokości. Dzięki temu "spadek" trwa do połowy lądowiska.
	curve_landing.add_point(
		Vector2(land_start_x, land_start_y), 
		Vector2.ZERO, 
		Vector2(diff_x * 0.4, diff_y * 0.8) # 80% spadku dzieje się na początku
	)
	
	# PUNKT 2: KONIEC LĄDOWANIA (STYK Z NASTĘPNYM TERENEM)
	# KLUCZOWE: in_vec MUSI BYĆ (X, 0) - CZYLI POZIOMY!
	# Jeśli in_vec.y byłoby dodatnie, zrobiłby się dołek.
	# Jeśli in_vec.y byłoby ujemne, zrobiłaby się górka przed końcem.
	# Vector2(-diff_x * 0.5, 0) -> Długa rączka pozioma wymusza gładkie wypłaszczenie.
	
	curve_landing.add_point(
		Vector2(land_end_x, land_end_y), 
		Vector2(-diff_x * 0.5, 0), # <--- TO NAPRAWIA "WCINANIE SIĘ"
		Vector2(100, 0)            # Wyjście na płasko do następnego chunka
	)
	
	build_island($LandingBody, curve_landing)
	
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
