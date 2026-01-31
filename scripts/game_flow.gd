# gdlint:ignore = class-definitions-order
extends Node

@export var roulette_scene: PackedScene = preload("res://scenes/ui/roulette_bar.tscn")
@export var shop_scene: PackedScene = preload("res://scenes/menu/shop.tscn")
@export var fireworks_scene: PackedScene = preload("res://scenes/ui/fireworks_effect.tscn")
@export var player_path: NodePath

var _player: Node = null
var _overlay: CanvasLayer
var _handled_death := false


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


func _on_player_died() -> void:
	if _handled_death:
		return
	_handled_death = true
	_pause_game()
	_show_roulette()


func _show_roulette() -> void:
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
			_start_new_run()
		"fireworks":
			await _play_fireworks(roulette)
			_start_new_run()
		_:
			if roulette != null:
				roulette.queue_free()
			_start_new_run()


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
	get_tree().paused = false
	get_tree().reload_current_scene()


func _play_fireworks(roulette: Node) -> void:
	if fireworks_scene == null:
		if roulette != null:
			roulette.queue_free()
		return
	var effect = fireworks_scene.instantiate()
	effect.process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.add_child(effect)
	if effect.has_signal("finished"):
		await effect.finished
	else:
		await get_tree().create_timer(1.2, false, true).timeout
	if roulette != null:
		roulette.queue_free()


func _pause_game() -> void:
	get_tree().paused = true


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
