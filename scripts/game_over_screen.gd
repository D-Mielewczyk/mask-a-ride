extends CanvasLayer
class_name GameOverScreen

@onready var title_label = $PanelContainer/VBoxContainer/TitleLabel
@onready var distance_label = $PanelContainer/VBoxContainer/DistanceLabel
@onready var money_label = $PanelContainer/VBoxContainer/MoneyLabel
@onready var restart_button = $PanelContainer/VBoxContainer/RestartButton

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)

func show_results(distance: float, money: float) -> void:
	distance_label.text = "Distance: %d m" % int(distance / 50)
	money_label.text = "Money: $%d" % int(money)
	visible = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
