extends RefCounted

const EPSILON := 0.001


func run() -> Array:
	var failures: Array = []
	var player_script := load("res://scripts/player.gd") as Script
	if player_script == null:
		failures.append("Player script not found at res://scripts/player.gd")
		return failures

	var player = player_script.new()
	if player == null:
		failures.append("Failed to instantiate Player")
		return failures

	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.root.add_child(player)
	player._ready()

	_assert_close(
		player.velocity.x, player.move_speed, "Initial velocity.x != move_speed", failures
	)

	# Bounce collision should add upward velocity and reduce x speed.
	var bounce := Node.new()
	bounce.add_to_group("obstacle_bounce")
	player.velocity = Vector2(300.0, 10.0)
	player.collide(bounce)
	_assert_true(player.velocity.y < 0.0, "Bounce did not send player upward", failures)
	_assert_true(player.velocity.x < 300.0, "Bounce did not reduce x velocity", failures)

	# Spike collision should kill the player.
	var spike := Node.new()
	spike.add_to_group("obstacle_spike")
	player.is_alive = true
	player.collide(spike)
	_assert_true(player.is_alive == false, "Spike collision did not kill player", failures)

	player.queue_free()
	return failures


func _assert_true(condition: bool, message: String, failures: Array) -> void:
	if not condition:
		failures.append(message)


func _assert_close(a: float, b: float, message: String, failures: Array) -> void:
	if absf(a - b) > EPSILON:
		failures.append("%s (%.4f vs %.4f)" % [message, a, b])
