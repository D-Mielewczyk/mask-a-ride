extends StaticBody2D

# --- KONFIGURACJA TERENU ---
@export var chunk_width: float = 1920.0
@export var num_hills: int = 2

# NOWOŚĆ: Rozdzielamy wchodzenie i schodzenie
@export var max_climb: float = 300.0  # Maksymalny wznios (mała liczba = łagodne górki)
@export var max_drop: float = 1200.0   # Maksymalny spadek (duża liczba = szybki zjazd)

@export var hill_roughness: float = 0.4
@export var tile_uv_scale: float = 0.08

# Zmienne wewnętrzne
var end_point_world: Vector2

func generate_terrain(start_world_pos: Vector2):
	position = Vector2(start_world_pos.x, 0)
	var local_start_y = start_world_pos.y
	
	var curve = Curve2D.new()

	# 1. PUNKT STARTOWY (Poziome wyjście)
	curve.add_point(Vector2(0, local_start_y), Vector2.ZERO, Vector2(100, 0))

	# 2. GENEROWANIE GÓREK
	var segment_step = chunk_width / num_hills
	var current_x = 0.0
	var current_y = local_start_y

	for i in range(num_hills):
		current_x += segment_step

		# --- NOWA LOGIKA WYSOKOŚCI ---
		
		# Domyślnie losujemy zmianę wysokości
		# Zakres: od "trochę w górę" (-max_climb) do "mocno w dół" (+max_drop)
		var height_change = randf_range(-max_climb, max_drop)
		
		# --- ZABEZPIECZENIE PRZED DZIURAMI (ANTI-HOLE SYSTEM) ---
		# Jeśli jesteśmy już bardzo głęboko (np. Y > 800), zmuszamy teren do pójścia w górę.
		if current_y > 800:
			height_change = randf_range(-max_climb * 2.0, -50.0) # Musi iść w górę
			print("Korekta: Zbyt głęboko, wychodzimy w górę.")
			
		# Jeśli jesteśmy za wysoko (np. Y < -200), pozwalamy na mocniejszy spadek.
		elif current_y < -200:
			height_change = randf_range(100.0, max_drop) # Musi iść w dół

		var target_y = current_y + height_change
		
		# Ostateczny bezpiecznik (clamp)
		target_y = clamp(target_y, -500, 1200)

		# --- RYSOWANIE ŁUKÓW ---
		var handle_length = segment_step * hill_roughness
		
		# Rączki poziom (y=0) dla gładkości
		# Wydłużamy "out_vec", żeby zjazd był bardziej płynny
		var in_vec = Vector2(-handle_length, 0)
		var out_vec = Vector2(handle_length * 1.2, 0) 
		
		curve.add_point(Vector2(current_x, target_y), in_vec, out_vec)
		current_y = target_y

	# --- WAŻNE: ZAMYKANIE CHUNKA PŁASKO ---
	# To naprawia łączenie z następnym kawałkiem
	var final_x = chunk_width
	# Lekko uśredniamy koniec, żeby nie kończyć na samym szczycie albo dnie
	var final_y = current_y 
	
	# Dodajemy punkt końcowy z rączką (100, 0) żeby następny chunk miał płaski start
	curve.add_point(Vector2(final_x, final_y), Vector2(-100, 0), Vector2(100, 0))
	end_point_world = position + Vector2(final_x, final_y)

	# --- RYSOWANIE GRAFIKI ---
	curve.bake_interval = 20.0 # Optymalizacja (było 10, 20 wystarczy)
	var baked_points = curve.get_baked_points()
	var poly_points = PackedVector2Array(baked_points)
	
	# Fundament
	poly_points.append(Vector2(chunk_width, 2000))
	poly_points.append(Vector2(0, 2000))
	
	$Polygon2D.polygon = poly_points
	$CollisionPolygon2D.polygon = poly_points
	$Line2D.points = baked_points

	# UV
	var uv_points = PackedVector2Array()
	for p in poly_points:
		uv_points.append(p * tile_uv_scale)
	$Polygon2D.uv = uv_points

func get_end_point():
	return end_point_world

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_screen_exited():

	# Chunk wyszedł całkowicie z ekranu -> usuwamy go z pamięci

	queue_free() 

func _ready():
	if $VisibleOnScreenNotifier2D:
		if not $VisibleOnScreenNotifier2D.screen_exited.is_connected(_on_screen_exited):
			$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)
