extends PowerUp
class_name MagnetPowerUp

func apply_effect(player: Player) -> void:
	super.apply_effect(player)
	# Attract nearby money/obstacles toward player
	print("Magnet activated!")
	await get_tree().create_timer(duration).timeout
	print("Magnet expired")
