# gdlint:ignore = class-definitions-order
extends Node

@export var ramp_scene: PackedScene = preload("res://scenes/downhill.tscn")
@export var roulette_scene: PackedScene = preload("res://scenes/ui/roulette_bar.tscn")
@export var shop_scene: PackedScene = preload("res://scenes/menu/shop.tscn")
@export var player_path: NodePath

var _player: Node = null
var _overlay: CanvasLayer
var _handled_death := false
var _next_lvl_processing := false

var current_goal_x: float = 25000.0
var level_count: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_flow")
	_player = _resolve_player()
	_bind_player(_player)
	get_tree().node_added.connect(_on_node_added)

	_overlay = CanvasLayer.new()
	_overlay.layer = 100
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)

func _process(delta: float) -> void:
	if _player:
			if (_player.global_position.x > current_goal_x) and not (_next_lvl_processing):
				print("KONIEC LV", _player.global_position.x, " ", current_goal_x)
				_reach_level_end()
				_next_lvl_processing = false
				
func _reach_level_end() -> void:
	_next_lvl_processing = true
	_pause_game()
	#_show_roulette()
	# Zwiększamy cel dla następnego poziomu
	current_goal_x += (level_count * 25000.0) 
	level_count += 1
	_spawn_next_ramp_and_launch()
	get_tree().paused = false
	_next_lvl_processing = false
	
func _spawn_next_ramp_and_launch() -> void:
	# zeby gasnicy nie mozna bylo uzwać na granicy poziomu
	_player.set_physics_process(false)

	var spawn_x = _player.global_position.x - 120
	var spawn_y = _player.global_position.y + 1800
	_player.linear_velocity = Vector2.ZERO
	_player.angular_velocity = 0
		# 3. IMPULS zamiast Tweena
	# Wektor: (X: lekko w przód, Y: bardzo mocno w górę)
	var launch_force = Vector2(0, -1500) 
	_player.apply_central_impulse(launch_force)
	_player.angular_velocity = 5.0
	
	await get_tree().create_timer(0.5).timeout

	# 3. Logika skoku (Tween)
	var jump_height = _player.global_position.y - 4000
	
	# 2. Instancjonowanie nowej rampy
	var new_ramp = ramp_scene.instantiate()
	get_tree().current_scene.add_child(new_ramp)
	
	# Parametry rampy
	
	var spawn_pos = Vector2(spawn_x, spawn_y)
	#var new_h = 1000.0 # Przykładowa wysokość
	
	new_ramp.add_to_group("starting_ramp")
	new_ramp.global_position = spawn_pos
	#new_ramp.set("start_height", new_h)

	_show_roulette() 

	# zeby gasnicy nie mozna bylo uzwać na granicy poziomu
	_player.set_physics_process(true)

func _on_player_died() -> void:
	if _handled_death:
		return
	_handled_death = true
	_pause_game()
	_reset_level_state()
	_start_new_run()


func _show_roulette() -> void:
	if _player != null and "current_fuel" in _player:
		_player.current_fuel = max(_player.current_fuel, 100)
	_pause_game()
	var roulette = roulette_scene.instantiate()
	roulette.process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.add_child(roulette)
	if roulette.has_signal("outcome_selected"):
		roulette.outcome_selected.connect(_on_roulette_outcome.bind(roulette))


func _on_roulette_outcome(outcome: String, roulette: Node) -> void:
	match outcome:
		"shop":
			if roulette != null:
				roulette.queue_free()
			_show_shop()
		"double":
			if roulette != null:
				roulette.queue_free()
			_double_coins()
		"fireworks":
			if roulette != null:
				roulette.queue_free()
		_:
			if roulette != null:
				roulette.queue_free()
	_resume_game()


func _show_shop() -> void:
	var shop = shop_scene.instantiate()
	shop.process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.add_child(shop)
	if shop.has_signal("closed"):
		shop.closed.connect(func(): _start_new_run())
	else:
		_start_new_run()


func _double_coins() -> void:
	if _player != null and "coins" in _player:
		_player.coins *= 2
		if _player.has_method("add_coins"):
			_player.add_coins(0)
	elif GlobalSingleton.global != null:
		GlobalSingleton.global.coins *= 2
		GlobalSingleton.global.save_coins()


func _start_new_run() -> void:
	_handled_death = false
	var tree = get_tree()
	if tree == null:
		return
	if GlobalSingleton.global != null:
		GlobalSingleton.global.reset_upgrades()
	tree.paused = false
	tree.reload_current_scene()



func _resume_from_death() -> void:
	_handled_death = false
	_resume_game()
	if _player != null and _player.has_method("revive"):
		_player.revive()


func _reset_level_state() -> void:
	current_goal_x = 25000.0
	level_count = 1
	_next_lvl_processing = false


func _pause_game() -> void:
	get_tree().paused = true

func _resume_game() -> void:
	get_tree().paused = false

func _resolve_player() -> Node:
	if player_path != NodePath():
		return get_node_or_null(player_path)
	return get_tree().get_first_node_in_group("player")


func handle_player_death() -> void:
	_on_player_died()


func _bind_player(node: Node) -> void:
	if node == null:
		return
	_player = node
	if _player.has_signal("died") and not _player.died.is_connected(_on_player_died):
		_player.died.connect(_on_player_died)


func _on_node_added(node: Node) -> void:
	if node == null:
		return
	if node.is_in_group("player"):
		_bind_player(node)
