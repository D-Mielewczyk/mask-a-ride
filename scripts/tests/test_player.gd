extends RefCounted

const EPSILON := 0.001


func run() -> Array:
	var failures: Array = []
	var player_script = load("res://scripts/player.gd")
	if player_script == null:
		failures.append("Player script not found at res://scripts/player.gd")
		return failures

	var player = player_script.new()
	if player == null:
		failures.append("Failed to instantiate Player")
		return failures

	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		failures.append("SceneTree not available")
		return failures

	tree.root.add_child(player)
	player._ready()

	_assert_close(player.velocity.x, player.move_speed, "Initial velocity.x != move_speed", failures)

	var start_x := player.position.x
	player.collision_cooldown = 0.05
	player._physics_process(0.1)

	_assert_true(player.distance_traveled > 0.0, "distance_traveled did not increase", failures)
	_assert_close(
		player.distance_traveled,
		player.position.x - start_x,
		"distance_traveled != actual delta x",
		failures
	)
	_assert_true(player.collision_cooldown == 0.0, "collision_cooldown did not clamp to 0", failures)

	player.queue_free()
	return failures


func _assert_true(condition: bool, message: String, failures: Array) -> void:
	if not condition:
		failures.append(message)


func _assert_close(a: float, b: float, message: String, failures: Array) -> void:
	if absf(a - b) > EPSILON:
		failures.append("%s (%.4f vs %.4f)" % [message, a, b])
