extends PowerUp
class_name SpeedBoostPowerUp

func apply_effect(player: Player) -> void:
	super.apply_effect(player)
	player.move_speed *= 1.5
	await get_tree().create_timer(duration).timeout
	player.move_speed /= 1.5
