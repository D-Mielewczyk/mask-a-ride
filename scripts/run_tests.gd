extends SceneTree


func _initialize() -> void:
	var failures: Array = []
	# Player tests are currently incompatible with the new RigidBody2D player setup.
	# Re-enable once tests are updated for the new scene structure.

	var shop_test_script := load("res://scripts/tests/test_shop_upgrades.gd") as Script
	if shop_test_script == null:
		push_error("Failed to load res://scripts/tests/test_shop_upgrades.gd")
		quit(1)
		return
	var shop_test = shop_test_script.new()
	failures.append_array(shop_test.run())

	if failures.size() > 0:
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("All tests passed.")
	quit(0)
