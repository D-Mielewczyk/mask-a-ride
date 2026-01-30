extends CanvasLayer
class_name HUD

@onready var distance_label = $VBoxContainer/DistanceLabel
@onready var money_label = $VBoxContainer/MoneyLabel

func _ready() -> void:
	SignalBus.money_collected.connect(_on_money_collected)

func update_distance(distance: float) -> void:
	if distance_label:
		distance_label.text = "Distance: %d m" % int(distance / 50)

func update_money(money: float) -> void:
	if money_label:
		money_label.text = "Money: $%d" % int(money)

func _on_money_collected(amount: float, position: Vector2) -> void:
	update_money(amount)
