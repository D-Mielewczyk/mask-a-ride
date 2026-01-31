class_name GlobalSingleton extends Node

static var global: GlobalSingleton = null

# Use this singleton in any scene with:
# Global.(function or field defined in this file)

var coins: int = 2000
var bought_upgrades: Dictionary = {}


func _init() -> void:
	if global == null:
		global = self
		load_upgrades()
	else:
		printerr("Trying to create another instance of MySingleton. Deleting it.")
		queue_free()


func set_upgrade_bought(upgrade_id: String, bought: bool) -> void:
	bought_upgrades[upgrade_id] = bought
	_save_upgrades()


func is_upgrade_bought(upgrade_id: String) -> bool:
	return bought_upgrades.get(upgrade_id, false)


func apply_upgrades_to(player: Node) -> void:
	var pool = ShopUpgradePool.new()
	pool.load_upgrades()
	for upgrade in pool.get_all():
		upgrade.bought = is_upgrade_bought(upgrade.id)
		if upgrade.bought:
			upgrade.apply_to(player)


func load_upgrades() -> void:
	var file = FileAccess.open("user://shop_upgrades.json", FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		bought_upgrades = data


func _save_upgrades() -> void:
	var file = FileAccess.open("user://shop_upgrades.json", FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(bought_upgrades))
