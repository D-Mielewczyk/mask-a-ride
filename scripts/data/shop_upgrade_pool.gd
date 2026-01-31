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
	var pool: Array[ShopUpgrade] = []
	for upgrade in _upgrades:
		if not _requirements_met(upgrade):
			continue
		if not include_owned and upgrade.bought:
			continue
		pool.append(upgrade)

	var options: Array[ShopUpgrade] = []
	while options.size() < count and pool.size() > 0:
		var pick = _weighted_pick(pool)
		if pick == null:
			break
		options.append(pick)
		pool.erase(pick)

	return options


func _weighted_pick(pool: Array[ShopUpgrade]) -> ShopUpgrade:
	var total := 0.0
	for upgrade in pool:
		total += _rarity_weight(upgrade.rarity)
	if total <= 0.0:
		return pool[0]

	var roll := randf() * total
	var accum := 0.0
	for upgrade in pool:
		accum += _rarity_weight(upgrade.rarity)
		if roll <= accum:
			return upgrade
	return pool[pool.size() - 1]


func _rarity_weight(rarity: String) -> float:
	match rarity:
		"rare":
			return 0.4
		"epic":
			return 0.2
		"legendary":
			return 0.1
		_:
			return 1.0


func _requirements_met(upgrade: ShopUpgrade) -> bool:
	if upgrade.requires_ids.is_empty():
		return true
	var global = GlobalSingleton.global
	if global == null:
		return false
	for req_id in upgrade.requires_ids:
		if not global.is_upgrade_bought(req_id):
			return false
	return true
	