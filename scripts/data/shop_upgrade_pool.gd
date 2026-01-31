# gdlint:ignore = class-definitions-order
extends Node
class_name ShopUpgradePool

@export var upgrades_dir := "res://data/upgrades"

var _upgrades: Array[ShopUpgrade] = []


func _ready() -> void:
	load_upgrades()


func load_upgrades() -> void:
	_upgrades.clear()
	var dir = DirAccess.open(upgrades_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var upgrade = load("%s/%s" % [upgrades_dir, file_name]) as ShopUpgrade
			if upgrade != null:
				_upgrades.append(upgrade)
		file_name = dir.get_next()
	dir.list_dir_end()


func get_all() -> Array[ShopUpgrade]:
	return _upgrades.duplicate()


func get_options(count: int, include_owned: bool) -> Array[ShopUpgrade]:
	var unowned: Array[ShopUpgrade] = []
	var owned: Array[ShopUpgrade] = []
	for upgrade in _upgrades:
		if upgrade.bought:
			owned.append(upgrade)
		else:
			unowned.append(upgrade)

	unowned.shuffle()
	owned.shuffle()

	var options: Array[ShopUpgrade] = []
	for upgrade in unowned:
		if options.size() >= count:
			break
		options.append(upgrade)

	if include_owned and options.size() < count:
		for upgrade in owned:
			if options.size() >= count:
				break
			options.append(upgrade)

	return options
