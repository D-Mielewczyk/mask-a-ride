extends RefCounted


func run() -> Array:
	var failures: Array = []
	var pool := ShopUpgradePool.new()
	pool.load_upgrades()

	var total_draws := 500
	var options_per_draw := 3
	var counts: Dictionary = {}

	for i in range(total_draws):
		var options = pool.get_options(options_per_draw, true)
		for upgrade in options:
			counts[upgrade.id] = counts.get(upgrade.id, 0) + 1

	if not counts.has("rocket"):
		failures.append("Rocket (fire extinguisher) never appeared in %d draws." % total_draws)
	return failures
