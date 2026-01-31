extends Node2D

# Gracz (referencja, żeby wiedzieć, gdzie generować teren)
@export var player_node: Node2D
@export var chunks_ahead: int = 10

# Załaduj scenę chunka (przeciągnij plik .tscn w inspektorze lub wpisz ścieżkę)
var terrain_scene = preload("res://scenes/terrain_chunk.tscn")
var chasm_scene = preload("res://scenes/chasm_chunk.tscn")

var next_spawn_pos = Vector2(1000, 2500)  # Startujemy na wysokości Y=300
var active_chunks = []
var chunk_width: float = 1920.0
var total_chunks_spawned: int = 0

func _ready():
	# Generujemy 3 kawałki na start
	for i in range(chunks_ahead):
		spawn_chunk()

func _process(_delta):
	if not player_node:
		return
		
	# LOGIKA NIESKOŃCZONOŚCI:
	# Sprawdzamy, gdzie jest gracz. Jeśli zbliża się do końca wygenerowanego świata
	# na odległość mniejszą niż np. 2 chunki, generujemy kolejny.
	
	# next_spawn_pos.x to koniec obecnego świata.
	# player_node.position.x to pozycja gracza.
	
	var view_distance = chunk_width * 50 # Bufor bezpieczeństwa
	
	while player_node.position.x + view_distance > next_spawn_pos.x:
		spawn_chunk()


func spawn_chunk():
	var new_chunk
	
	# --- BEZPIECZNY START ---
	# Jeśli stworzyliśmy mniej niż 2 chunki, wymuszamy zwykły teren.
	# Dzięki temu start jest zawsze bezpieczny.
	if total_chunks_spawned < 3:
		new_chunk = terrain_scene.instantiate()
		print("Start: Bezpieczny teren")
		
	# --- NORMALNA ROZGRYWKA ---
	# Dopiero od 3. kawałka pozwalamy na losowanie przepaści
	else:
		if randf() < 0.2: # 20% szans na przepaść
			new_chunk = chasm_scene.instantiate()
			print("Losowanie: PRZEPAŚĆ!")
		else:
			new_chunk = terrain_scene.instantiate()
			print("Losowanie: Teren")

	# Reszta kodu bez zmian...
	add_child(new_chunk)
	new_chunk.generate_terrain(next_spawn_pos)
	next_spawn_pos = new_chunk.get_end_point()
	
	# --- WAŻNE: ZWIĘKSZ LICZNIK ---
	total_chunks_spawned += 1
