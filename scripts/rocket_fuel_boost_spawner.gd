# gdlint:ignore = class-definitions-order
extends Node2D

@export var boost_scene: PackedScene = preload("res://scenes/pickups/rocket_fuel_boost.tscn")
@export var spawn_interval_min: float = 1.5
@export var spawn_interval_max: float = 3.5
@export var max_alive: int = 6
@export var spawn_distance_min: float = 1800.0
@export var spawn_distance_max: float = 3200.0
@export var min_player_x_to_spawn: float = 0.0
@export var air_height_min: float = 180.0
@export var air_height_max: float = 650.0
@export var avoid_on_screen: bool = true
@export var player_path: NodePath

var _time_accum := 0.0
var _next_spawn_time := 0.0


func _ready() -> void:
	_next_spawn_time = randf_range(spawn_interval_min, spawn_interval_max)


func _process(delta: float) -> void:
	_time_accum += delta
	if _time_accum < _next_spawn_time:
		return
	_time_accum = 0.0
	_next_spawn_time = randf_range(spawn_interval_min, spawn_interval_max)

	if _alive_count() >= max_alive:
		return

	var global = GlobalSingleton.global
	if global == null or not global.is_upgrade_bought("rocket_fuel_boost_pickup"):
		return

	var player = get_node_or_null(player_path) as Node2D
	if player == null:
		return

	if player.global_position.x < min_player_x_to_spawn:
		return

	_spawn_boost(player)


func _spawn_boost(player: Node2D) -> void:
	var screen_w = get_viewport_rect().size.x
	if screen_w <= 0.0:
		screen_w = 1280.0
	var dist = randf_range(spawn_distance_min, spawn_distance_max)
	dist = max(dist, screen_w * 0.6)
	var x = player.global_position.x + dist
	var y = player.global_position.y - randf_range(air_height_min, air_height_max)
	var spawn_pos = Vector2(x, y)

	if avoid_on_screen:
		if abs(spawn_pos.x - player.global_position.x) < screen_w * 0.6:
			return

	var boost = boost_scene.instantiate()
	boost.global_position = spawn_pos
	add_child(boost)
	print("Rocket fuel boost spawned at ", spawn_pos)


func _alive_count() -> int:
	var count := 0
	for child in get_children():
		if child is Area2D:
			count += 1
	return count
