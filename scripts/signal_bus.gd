extends Node
class_name SignalBus

# Player signals
signal player_died(distance: float, money: float)

# Obstacle signals
signal obstacle_hit(obstacle: Obstacle, money_value: float)
signal money_spawned(amount: float, position: Vector2)

# PowerUp signals
signal powerup_collected(type: String, player: Player)

# Game signals
signal money_collected(amount: float, position: Vector2)
signal distance_updated(distance: float)
signal game_paused
signal game_resumed
