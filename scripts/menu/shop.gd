# gdlint:ignore = class-definitions-order
extends Control

@export var decision_time := 10.0

var _time_left := 0.0
var _options: Array[ShopUpgrade] = []
var _pool := ShopUpgradePool.new()

@onready var money_label: Label = $Frame/Layout/Header/MoneyPanel/MoneyRow/MoneyLabel
@onready var decision_bar: ProgressBar = $Frame/Layout/DecisionProgress
@onready var decision_label: Label = $Frame/Layout/DecisionProgress/DecisionTimeLabel
@onready var option_roots: Array[Node] = [
	$Frame/Layout/OptionsRow/Option1,
	$Frame/Layout/OptionsRow/Option2,
	$Frame/Layout/OptionsRow/Option3
]


func _ready() -> void:
	_time_left = decision_time
	_pool.load_upgrades()
	_sync_bought_flags()
	_pick_options()
	_update_money()
	_update_timer()
	_update_progress()
	_connect_buttons()


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left = maxf(_time_left - delta, 0.0)
	_update_timer()
	_update_progress()
	if _time_left <= 0.0:
		_lock_shop()


func _connect_buttons() -> void:
	for index in range(option_roots.size()):
		var button = option_roots[index].get_node("Option%dContent/Option%dBuy" % [index + 1, index + 1]) as Button
		if button != null and not button.pressed.is_connected(_on_buy_pressed.bind(index)):
			button.pressed.connect(_on_buy_pressed.bind(index))


func _pick_options() -> void:
	_options = _pool.get_options(option_roots.size(), true)
	for index in range(option_roots.size()):
		if index < _options.size():
			_render_option(index, _options[index])
		else:
			option_roots[index].visible = false


func _render_option(index: int, upgrade: ShopUpgrade) -> void:
	var root = option_roots[index]
	root.visible = true

	var icon = root.get_node("Option%dContent/Option%dImage" % [index + 1, index + 1]) as TextureRect
	var name_label = root.get_node("Option%dContent/Option%dName" % [index + 1, index + 1]) as Label
	var desc_label = root.get_node("Option%dContent/Option%dDescription" % [index + 1, index + 1]) as Label
	var price_label = root.get_node("Option%dContent/Option%dPrice/Option%dPriceLabel" % [index + 1, index + 1, index + 1]) as Label
	var buy_button = root.get_node("Option%dContent/Option%dBuy" % [index + 1, index + 1]) as Button
	var rarity_label = root.get_node("Option%dContent/Option%dRarity" % [index + 1, index + 1]) as Label

	if icon != null and upgrade.icon != null:
		icon.texture = upgrade.icon
	if name_label != null:
		name_label.text = upgrade.display_name
	if desc_label != null:
		desc_label.text = upgrade.description
	if price_label != null:
		price_label.text = str(upgrade.price)
	_apply_card_style(root, upgrade.rarity)
	if rarity_label != null:
		rarity_label.text = _rarity_label_text(upgrade.rarity)
		rarity_label.modulate = _rarity_label_color(upgrade.rarity)

	_update_button_state(upgrade, buy_button)


func _update_button_state(upgrade: ShopUpgrade, button: Button) -> void:
	if button == null:
		return
	if upgrade.bought:
		button.text = "Owned"
		button.disabled = true
		return

	var can_afford = _get_money() >= upgrade.price
	button.text = "Buy"
	button.disabled = not can_afford or _time_left <= 0.0


func _on_buy_pressed(index: int) -> void:
	if index >= _options.size():
		return
	var upgrade = _options[index]
	if upgrade.bought:
		return
	var global = GlobalSingleton.global
	if global == null:
		return
	if global.money < upgrade.price:
		return
	global.money -= upgrade.price
	upgrade.bought = true
	global.set_upgrade_bought(upgrade.id, true)
	_update_money()
	_render_option(index, upgrade)


func _update_money() -> void:
	money_label.text = str(_get_money())
	for index in range(_options.size()):
		var button = option_roots[index].get_node("Option%dContent/Option%dBuy" % [index + 1, index + 1]) as Button
		_update_button_state(_options[index], button)


func _get_money() -> int:
	if GlobalSingleton.global != null:
		return GlobalSingleton.global.money
	return 0


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


func _sync_bought_flags() -> void:
	var global = GlobalSingleton.global
	if global == null:
		return
	global.load_upgrades()
	for upgrade in _pool.get_all():
		upgrade.bought = global.is_upgrade_bought(upgrade.id)


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"rare":
			return Color(0.2, 0.6, 1.0, 1.0)
		"epic":
			return Color(0.6, 0.2, 1.0, 1.0)
		"legendary":
			return Color(1.0, 0.55, 0.1, 1.0)
		_:
			return Color(0, 0, 0, 0)


func _apply_card_style(card: PanelContainer, rarity: String) -> void:
	var base = _rarity_color(rarity)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.4, 1)
	style.shadow_size = 24 if base.a > 0.0 else 0
	style.shadow_offset = Vector2(0, 0)
	style.shadow_color = Color(base.r, base.g, base.b, 1.0)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	card.add_theme_stylebox_override("panel", style)


func _rarity_label_text(rarity: String) -> String:
	match rarity:
		"rare":
			return "RARE"
		"epic":
			return "EPIC"
		"legendary":
			return "LEGENDARY"
		_:
			return "COMMON"


func _rarity_label_color(rarity: String) -> Color:
	return _rarity_color(rarity)
