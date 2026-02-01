class_name GlobalSingleton extends Node

static var global: GlobalSingleton = null

# Use this singleton in any scene with:
# Global.(function or field defined in this file)

var coins: int = 0
var bought_upgrades: Dictionary = {}
var level_count: int = 1
var current_goal_x: float = 20000.0

func _init() -> void:
	if global == null:
		global = self
		reset_upgrades()
		reset_coins()
	else:
		printerr("Trying to create another instance of MySingleton. Deleting it.")
		queue_free()


func set_upgrade_bought(upgrade_id: String, bought: bool) -> void:
	bought_upgrades[upgrade_id] = bought


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
	return


func _save_upgrades() -> void:
	return


func reset_upgrades() -> void:
	bought_upgrades.clear()
	bought_upgrades["rocket"] = true

func reset_coins() -> void:
	coins = 0
