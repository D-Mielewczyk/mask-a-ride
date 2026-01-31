extends StaticBody2D

# --- KONFIGURACJA TERENU ---
@export var chunk_width: float = 1920.0
@export var num_hills: int = 2

# NOWOŚĆ: Rozdzielamy wchodzenie i schodzenie
@export var max_climb: float = 300.0  # Maksymalny wznios (mała liczba = łagodne górki)
@export var max_drop: float = 1200.0   # Maksymalny spadek (duża liczba = szybki zjazd)

@export var hill_roughness: float = 0.4
@export var tile_uv_scale: float = 0.2

# Zmienne wewnętrzne
var end_point_world: Vector2

func generate_terrain(start_world_pos: Vector2):
	position = Vector2(start_world_pos.x, 0)
	var local_start_y = start_world_pos.y
	var local_start_x = start_world_pos.x
	
	var curve = Curve2D.new()

	# Obliczamy szerokość jednego segmentu
	var segment_step = chunk_width / num_hills
	
	# --- POPRAWKA: DŁUGIE RĄCZKI NA ŁĄCZENIACH ---
	# Zamiast sztywnego "100", używamy 40-50% szerokości segmentu.
	# Dzięki temu start chunka jest płaski i stabilny przez długi czas.
	var connection_handle_len = segment_step * 0.5 

	# 1. PUNKT STARTOWY
	# in_vec: (-connection_handle_len, 0) - symuluje ciągłość z poprzedniego chunka
	# out_vec: (connection_handle_len, 0) - płynne wejście w ten chunk
	curve.add_point(
		Vector2(0, local_start_y), 
		Vector2(-connection_handle_len, 0), 
		Vector2(connection_handle_len, 0)
	)

	# 2. GENEROWANIE GÓREK
	var current_x = 0.0
	var current_y = local_start_y

	for i in range(num_hills):
		current_x += segment_step

		# Losowanie wysokości (Twoja logika)
		var height_change = randf_range(-max_climb, max_drop)
		
		# Anti-Hole system
		if current_y > 800:
			height_change = randf_range(-max_climb * 2.0, -50.0)
			print("Korekta: Zbyt głęboko, wychodzimy w górę.")
		elif current_y < -200:
			height_change = randf_range(100.0, max_drop)

		var target_y = current_y + height_change
		target_y = clamp(target_y, -500, 1200)

		# Rysowanie łuków wewnątrz chunka
		var handle_length = segment_step * hill_roughness
		
		# Delikatnie asymetryczne rączki dla lepszego flow
		var in_vec = Vector2(-handle_length, 0)
		var out_vec = Vector2(handle_length * 1.2, 0) 
		
		curve.add_point(Vector2(current_x, target_y), in_vec, out_vec)
		current_y = target_y

	# --- 3. ZAMYKANIE CHUNKA (Poprawione) ---
	var final_x = chunk_width
	var final_y = current_y 
	
	# Dodajemy punkt końcowy. 
	# KLUCZOWE: Używamy tej samej dużej wartości connection_handle_len co na starcie.
	# To gwarantuje, że koniec tego chunka i początek następnego będą miały
	# identyczną "siłę" wygładzania.
	curve.add_point(
		Vector2(final_x, final_y), 
		Vector2(-connection_handle_len, 0), 
		Vector2(connection_handle_len, 0) # Rączka wychodząca dla następnego chunka (teoretyczna)
	)
	
	end_point_world = position + Vector2(final_x, final_y)

	# --- RYSOWANIE GRAFIKI ---
	curve.bake_interval = 20.0
	var baked_points = curve.get_baked_points()
	var poly_points = PackedVector2Array(baked_points)
	
	poly_points.append(Vector2(chunk_width, 2000))
	poly_points.append(Vector2(0, 2000))
	
	$Polygon2D.polygon = poly_points
	$CollisionPolygon2D.polygon = poly_points
	$Line2D.points = baked_points
	_register_surface($Line2D)

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


func _register_surface(line: Line2D) -> void:
	if line == null:
		return
	if not line.is_in_group("terrain_surface"):
		line.add_to_group("terrain_surface")
