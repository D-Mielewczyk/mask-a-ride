class_name GlobalSingleton extends Node

static var global: GlobalSingleton = null

# Use this singleton in any scene with:
# Global.(fuction or field defined in this file)s


func _init() -> void:
	if global == null:
		global = self
	else:
		printerr("Trying to create another instance of MySingleton. Deleting it.")
		queue_free()
