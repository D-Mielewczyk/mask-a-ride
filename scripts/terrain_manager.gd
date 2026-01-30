extends Node2D

# Gracz (referencja, żeby wiedzieć, gdzie generować teren)
@export var player_node: Node2D

# Załaduj scenę chunka (przeciągnij plik .tscn w inspektorze lub wpisz ścieżkę)
var terrain_scene = preload("res://scenes/terrain_chunk.tscn")
var chasm_scene = preload("res://scenes/chasm_chunk.tscn")

var next_spawn_pos = Vector2(0, 300)  # Startujemy na wysokości Y=300
var active_chunks = []


func _ready():
	# Generujemy 3 kawałki na start
	for i in range(10):
		spawn_chunk()

func _process(_delta):
	# Jeśli gracz nie jest przypisany, nic nie rób (żeby nie wywaliło błędu)
	if not player_node:
		return

	# Sprawdź, czy gracz zbliża się do końca ostatniego chunka
	# next_spawn_pos.x to koniec świata. Jeśli gracz jest bliżej niż 2000px:
	if player_node.position.x > next_spawn_pos.x - 2000:
		spawn_chunk()


func spawn_chunk():
	var new_chunk
	
	# Prosta losowość: 20% szans na przepaść
	# Ale UWAGA: Nie generuj przepaści jako pierwszej (bo gracz spadnie na starcie)
	if active_chunks.size() > 2 and randf() < 0.2:
		new_chunk = chasm_scene.instantiate()
		print("Generuję PRZEPAŚĆ!")
	else:
		new_chunk = terrain_scene.instantiate()
		print("Generuję zwykły teren.")

	add_child(new_chunk)

	# Generuj teren zaczynając od punktu zakończenia poprzedniego
	new_chunk.generate_terrain(next_spawn_pos)

	# Zaktualizuj punkt startowy dla następnego
	next_spawn_pos = new_chunk.get_end_point()

	active_chunks.append(new_chunk)
