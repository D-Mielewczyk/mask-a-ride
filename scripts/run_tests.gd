extends SceneTree


func _initialize() -> void:
	var failures: Array = []

	var player_test = load("res://scripts/tests/test_player.gd").new()
	failures.append_array(player_test.run())

	if failures.size() > 0:
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("All tests passed.")
	quit(0)
