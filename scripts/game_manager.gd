extends Node2D
class_name GameManager

@export var obstacle_scenes: Array[PackedScene] = []
@export var powerup_scenes: Array[PackedScene] = []
@export var spawn_distance: float = 800.0
@export var spawn_interval: float = 2.0

@onready var player = $Player
@onready var hud = $HUD
@onready var game_over_screen = $GameOverScreen
@onready var pause_menu = $PauseMenu

var is_paused: bool = false
var spawn_timer: float = 0.0
var last_spawn_x: float = 0.0

func _ready() -> void:
	# Register SignalBus as autoload (global)
	if not get_tree().root.get_node_or_null("SignalBus"):
		get_tree().root.add_child(SignalBus.new())
		SignalBus.name = "SignalBus"
	
	# Load obstacles and powerups
	obstacle_scenes = [
		preload("res://scenes/obstacles/car.tscn"),
		preload("res://scenes/obstacles/truck.tscn"),
		preload("res://scenes/obstacles/box.tscn"),
		preload("res://scenes/obstacles/wall.tscn"),
	]
	
	powerup_scenes = [
		preload("res://scenes/powerups/speed_boost.tscn"),
		preload("res://scenes/powerups/shield.tscn"),
		preload("res://scenes/powerups/magnet.tscn"),
	]
	
	# Connect signals
	SignalBus.player_died.connect(_on_player_died)
	SignalBus.obstacle_hit.connect(_on_obstacle_hit)
	
	# Start initial terrain
	generate_initial_terrain()
	
	game_over_screen.visible = false
	pause_menu.visible = false

func _physics_process(delta: float) -> void:
	if not player.is_alive:
		return
	
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()
	
	# Spawn obstacles
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_obstacle()
		spawn_timer = 0.0
	
	# Update HUD
	hud.update_distance(player.distance_traveled)
	hud.update_money(player.money_collected)

func spawn_obstacle() -> void:
	"""Spawn random obstacle ahead of player"""
	if not obstacle_scenes:
		return
	
	var scene = obstacle_scenes[randi() % obstacle_scenes.size()]
	var obstacle = scene.instantiate()
	add_child(obstacle)
	
	# Position ahead of player
	obstacle.position.x = player.position.x + spawn_distance + randf_range(-100, 100)
	obstacle.position.y = randf_range(100, 600)

func spawn_powerup() -> void:
	"""Spawn random powerup"""
	if not powerup_scenes:
		return
	
	var scene = powerup_scenes[randi() % powerup_scenes.size()]
	var powerup = scene.instantiate()
	add_child(powerup)
	
	powerup.position.x = player.position.x + spawn_distance
	powerup.position.y = randf_range(100, 600)

func generate_initial_terrain() -> void:
	"""Create starting platforms"""
	for i in range(10):
		var terrain = preload("res://scenes/terrain.tscn").instantiate()
		add_child(terrain)
		terrain.position.x = i * 250
		terrain.position.y = 600

func toggle_pause() -> void:
	"""Toggle pause state"""
	is_paused = !is_paused
	get_tree().paused = is_paused
	pause_menu.visible = is_paused
	
	if is_paused:
		SignalBus.game_paused.emit()
	else:
		SignalBus.game_resumed.emit()

func _on_player_died(distance: float, money: float) -> void:
	"""Handle player death"""
	game_over_screen.show_results(distance, money)
	game_over_screen.visible = true

func _on_obstacle_hit(obstacle: Obstacle, money_value: float) -> void:
	"""Handle obstacle hit"""
	player.collect_money(money_value)
