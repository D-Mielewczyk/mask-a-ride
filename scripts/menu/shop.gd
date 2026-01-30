extends Control

@export var decision_time := 10.0
@onready var money_label: Label = $Frame/Layout/Header/MoneyPanel/MoneyRow/MoneyLabel
@onready var decision_bar: ProgressBar = $Frame/Layout/DecisionProgress
@onready var decision_label: Label = $Frame/Layout/DecisionProgress/DecisionTimeLabel

var _time_left := 0.0

func _ready() -> void:
	_time_left = decision_time
	_update_money()
	_update_timer()
	_update_progress()


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left = maxf(_time_left - delta, 0.0)
	_update_timer()
	_update_progress()
	if _time_left <= 0.0:
		_lock_shop()


func _update_money() -> void:
	var amount := 0
	if GlobalSingleton.global != null:
		amount = GlobalSingleton.global.money
	money_label.text = str(amount)


func _update_timer() -> void:
	decision_label.text = "%ds" % int(ceil(_time_left))


func _lock_shop() -> void:
	for node in get_tree().get_nodes_in_group("shop_buy_button"):
		var button := node as Button
		if button != null:
			button.disabled = true


func _update_progress() -> void:
	decision_bar.max_value = decision_time
	decision_bar.value = _time_left
