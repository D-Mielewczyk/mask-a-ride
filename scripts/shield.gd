extends PowerUp
class_name ShieldPowerUp

func apply_effect(player: Player) -> void:
	super.apply_effect(player)
	# Add visual shield
	var shield = ColorRect.new()
	shield.color = Color(0, 0.5, 1, 0.3)
	player.add_child(shield)
	
	# Invincibility for duration
	await get_tree().create_timer(duration).timeout
	shield.queue_free()
