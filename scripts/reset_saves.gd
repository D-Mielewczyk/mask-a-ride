# gdlint:ignore = class-definitions-order
extends SceneTree

const UPGRADES_SAVE_PATH := "user://shop_upgrades.json"
const COINS_SAVE_PATH := "user://coins.json"


func reset_upgrades() -> void:
	_delete_file(UPGRADES_SAVE_PATH)
	if GlobalSingleton.global != null:
		GlobalSingleton.global.bought_upgrades.clear()


func reset_coins() -> void:
	_delete_file(COINS_SAVE_PATH)
	if GlobalSingleton.global != null:
		GlobalSingleton.global.coins = 0


func reset_all() -> void:
	reset_upgrades()
	reset_coins()


func _delete_file(path: String) -> void:
	if FileAccess.file_exists(path):
		var err = DirAccess.remove_absolute(path)
		if err != OK:
			printerr("Failed to delete save file: ", path, " error: ", err)


func _ready() -> void:
	var args = OS.get_cmdline_args()
	if args.has("reset-upgrades"):
		reset_upgrades()
	elif args.has("reset-coins"):
		reset_coins()
	elif args.has("reset-all"):
		reset_all()
	else:
		print("Usage: godot --headless --path . --script scripts/reset_saves.gd -- reset-upgrades|reset-coins|reset-all")
	quit()
