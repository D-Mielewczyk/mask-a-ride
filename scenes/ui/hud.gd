extends CanvasLayer

@onready var dist_label = $Control/VBoxContainer/DistanceLabel
@onready var max_dist_label = $Control/VBoxContainer/MaxDistanceLabel
@onready var speed_label = $Control/VBoxContainer/SpeedLabel
@onready var height_label = $Control/VBoxContainer/HeightLabel
@onready var fuel_bar = $Control/ProgressBar
@onready var coins_label = $Control/HBoxContainer/CoinsLabel

var player: RigidBody2D
var max_distance: float = 0.0
var start_pos_x: float = 0.0

func _ready():
	# Czekamy krótką chwilę, aby upewnić się, że gracz zdążył się załadować
	await get_tree().process_frame
	
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		print("✅ HUD: Znaleziono gracza!")
		start_pos_x = player.global_position.x
		if "max_fuel" in player:
			fuel_bar.max_value = player.max_fuel
		else:
			print("⚠️ HUD: Gracz nie ma zmiennej 'max_fuel'!")
	else:
		print("❌ HUD: Nie znaleziono węzła w grupie 'player'! Sprawdź czy gracz ma add_to_group('player')")

func _process(_delta):
	if not player:
		# Próbujemy znaleźć gracza ponownie, jeśli go zgubiliśmy
		player = get_tree().get_first_node_in_group("player")
		return
	
	# Obliczanie dystansu
	var current_dist = max(0, (player.global_position.x - start_pos_x) / 100.0)
	if current_dist > max_distance:
		max_distance = current_dist
	
	# Aktualizacja tekstów
	dist_label.text = "Dystans: %d m" % current_dist
	max_dist_label.text = "Rekord: %d m" % max_distance
	speed_label.text = "Prędkość: %d km/h" % (player.linear_velocity.length() / 10.0)
	
	# Wysokość (Y w dół to wartości dodatnie, więc odejmujemy od jakiegoś poziomu lub używamy minusa)
	height_label.text = "Wysokość: %d m" % abs(player.global_position.y / 10.0)
	
	# Paliwo i Monety
	if "current_fuel" in player:
		fuel_bar.value = player.current_fuel
	
	if GlobalSingleton.global != null:
		coins_label.text = str(GlobalSingleton.global.coins)
	elif "coins" in player:
		coins_label.text = str(player.coins)
	
	# Debugowanie wartości w konsoli co jakiś czas (np. raz na 60 klatek)
	if Engine.get_frames_drawn() % 60 == 0:
		print("DEBUG: Dystans: ", current_dist, " Prędkość: ", player.linear_velocity.length())
