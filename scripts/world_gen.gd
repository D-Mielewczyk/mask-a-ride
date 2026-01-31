extends StaticBody2D

# Konfiguracja "Krzywizny" i "Hopek"
@export var chunk_width: float = 1920.0  # Szerokość jednego kawałka terenu
@export var num_hills: int = 2  # Ile górek na jeden kawałek (zagęszczenie)
@export var height_variation: float = 700.0  # Jak bardzo góra/dół skacze Y
@export var hill_roughness: float = 0.4  # Siła "wygięcia" (0 = płasko, 1 = pętle)

# Zmienne wewnętrzne
var end_point_world: Vector2  # Tu zapiszemy, gdzie ten chunk się kończy


func generate_terrain(start_world_pos: Vector2):
	# Ustawiamy ten chunk w miejscu startu (w osi X)
	position = Vector2(start_world_pos.x, 0)

	# Ponieważ przesunęliśmy cały węzeł (position),
	# nasze punkty lokalne zaczynamy od X=0.
	# Ale Y musimy dopasować do Y poprzedniego chunka.
	var local_start_y = start_world_pos.y

	var curve = Curve2D.new()

	# --- PUNKT STARTOWY (Połączenie z poprzednim terenem) ---
	# Żeby było gładko, control_out powinien być "w prawo"
	curve.add_point(Vector2(0, local_start_y), Vector2.ZERO, Vector2(100, 0))

	# --- GENEROWANIE GÓREK (HOPEK) ---
	var segment_step = chunk_width / num_hills
	var current_x = 0.0
	var current_y = local_start_y

	for i in range(num_hills):
		current_x += segment_step

		# 1. Losuj nową wysokość (baza + losowość)
		# Używamy randf_range, żeby teren szedł trochę w dół, trochę w górę
		var target_y = current_y + randf_range(-height_variation, height_variation)

		# Ogranicznik, żeby nie poszło za wysoko/nisko w nieskończoność
		target_y = clamp(target_y, -500, 1000)

# 2. Losuj "Hopki" - WERSJA GŁADKA (SMOOTH)
		
		# Zwiększamy bazową długość rączki. 
		# Wcześniej było * hill_roughness (0.5). Dajmy więcej, żeby łuki były szersze.
		# Wartość 0.5 * segment_step to "połowa drogi do sąsiada".
		var handle_length = segment_step * hill_roughness # Eksperymentuj z 0.3 do 0.6
		
		# in_handle (w lewo): MUSI BYĆ POZIOME (y=0)
		# Usuwamy losowanie Y. Zostawiamy tylko losową długość.
		var in_vec = Vector2(-handle_length * randf_range(0.8, 1.5), 0)
		
		# out_handle (w prawo): MUSI BYĆ POZIOME (y=0)
		var out_vec = Vector2(handle_length * randf_range(0.8, 1.5), 0)
		
		# UWAGA: Usunęliśmy in_vec.y = ... oraz out_vec.y = ...
		# To one odpowiadały za "ostre zęby" terenu.
		
		curve.add_point(Vector2(current_x, target_y), in_vec, out_vec)

		# Zapamiętaj Y dla następnej pętli
		current_y = target_y

	# --- BUDOWANIE GEOMETRII ---
	curve.bake_interval = 10.0
	var baked_points = curve.get_baked_points()
	var poly_points = PackedVector2Array(baked_points)

	# Zamykanie do dołu (fundament)
	poly_points.append(Vector2(chunk_width, 2000))
	poly_points.append(Vector2(0, 2000))

	# Przypisanie do węzłów
	$Polygon2D.polygon = poly_points
	$CollisionPolygon2D.polygon = poly_points
	$Line2D.points = baked_points  # Śnieg tylko na wierzchu

	# --- WYGENERUJ UV (Dla tekstury ziemi) ---
	var uv_points = PackedVector2Array()
	for p in poly_points:
		uv_points.append(p / 100.0)  # Skalowanie tekstury
	$Polygon2D.uv = uv_points

	# Oblicz punkt końcowy w koordynatach świata (dla następnego chunka)
	# local_end_point to (chunk_width, current_y)
	end_point_world = position + Vector2(chunk_width, current_y)


# Funkcja zwracająca, gdzie ten chunk się kończy
func get_end_point():
	return end_point_world


# Sprzątanie terenu, gdy wyjdzie poza ekran (ważne dla optymalizacji!)
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
	
func _ready():
	# Połącz sygnał, jeśli nie zrobiłeś tego w edytorze
	# (Zakładając, że węzeł nazywa się VisibleOnScreenNotifier2D)
	$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)

func _on_screen_exited():
	# Chunk wyszedł całkowicie z ekranu -> usuwamy go z pamięci
	queue_free()
