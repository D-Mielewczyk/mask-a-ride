extends SceneTree


func _initialize() -> void:
	var failures: Array = []

	var player_test_script := load("res://scripts/tests/test_player.gd") as Script
	if player_test_script == null:
		push_error("Failed to load res://scripts/tests/test_player.gd")
		quit(1)
		return
	var player_test = player_test_script.new()
	failures.append_array(player_test.run())

	if failures.size() > 0:
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("All tests passed.")
	quit(0)
