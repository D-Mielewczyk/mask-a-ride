# Script to validate Godot project loads without errors
extends SceneTree

func _ready() -> void:
	print("Validating Godot project...")
	
	# Try to load main scene
	var main_scene = "res://scenes/main.tscn"
	var scene = ResourceLoader.load(main_scene)
	
	if scene == null:
		print("ERROR: Failed to load main scene: ", main_scene)
		get_tree().quit(1)
		return
	
	print("✓ Main scene loaded successfully")
	
	# Check if player exists in main scene
	var player = scene.instantiate()
	if player.find_child("Player") == null:
		print("WARNING: Player not found in main scene")
	else:
		print("✓ Player found in main scene")
	
	player.free()
	
	print("✓ Project validation passed")
	get_tree().quit(0)
