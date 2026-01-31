# gdlint:ignore = class-definitions-order
extends Control

signal outcome_selected(outcome: String)

@export var weight_nothing := 0.59
@export var weight_shop := 0.3
@export var weight_double := 0.1
@export var weight_resurrect := 0.01
@export var spin_duration := 4.0
@export var spins := 5
@export var radius_x := 150.0
@export var radius_y := 70.0
@export var scale_min := 0.7
@export var scale_max := 1.0

@onready var wheel_area: Control = $Panel/Layout/WheelArea
@onready var wheel: Node2D = $Panel/Layout/WheelArea/Wheel
@onready var slot_nothing: Control = $Panel/Layout/WheelArea/Wheel/SlotNothing
@onready var slot_shop: Control = $Panel/Layout/WheelArea/Wheel/SlotShop
@onready var slot_double: Control = $Panel/Layout/WheelArea/Wheel/SlotDouble
@onready var slot_resurrect: Control = $Panel/Layout/WheelArea/Wheel/SlotResurrect
@onready var label_nothing: Label = $Panel/Layout/WheelArea/Wheel/SlotNothing/SlotNothingContent/SlotNothingLabel
@onready var label_shop: Label = $Panel/Layout/WheelArea/Wheel/SlotShop/SlotShopContent/SlotShopLabel
@onready var label_double: Label = $Panel/Layout/WheelArea/Wheel/SlotDouble/SlotDoubleContent/SlotDoubleLabel
@onready var label_resurrect: Label = $Panel/Layout/WheelArea/Wheel/SlotResurrect/SlotResurrectContent/SlotResurrectLabel
@onready var result_label: Label = $Panel/Layout/ResultLabel

var _outcomes := ["nothing", "shop", "double", "resurrect"]
var _base_angles := [0.0, TAU / 4.0, 2.0 * TAU / 4.0, 3.0 * TAU / 4.0]
var _current_angle := 0.0
var _spinning := false


func _ready() -> void:
	_update_labels()
	_update_wheel_positions()
	spin()


func _process(_delta: float) -> void:
	if _spinning:
		_update_wheel_positions()


func _update_wheel_positions() -> void:
	var center = wheel_area.size * 0.5
	wheel.position = center
	_place_slot(slot_nothing, _base_angles[0] + _current_angle)
	_place_slot(slot_shop, _base_angles[1] + _current_angle)
	_place_slot(slot_double, _base_angles[2] + _current_angle)
	_place_slot(slot_resurrect, _base_angles[3] + _current_angle)


func _place_slot(slot: Control, angle: float) -> void:
	var offset = Vector2(cos(angle) * radius_x, sin(angle) * radius_y)
	var depth = (sin(angle) + 1.0) * 0.5
	var scale = lerp(scale_min, scale_max, depth)
	slot.position = offset - (slot.size * 0.5) * scale
	slot.scale = Vector2(scale, scale)
	slot.z_index = int(depth * 100)


func spin() -> void:
	var outcome = _weighted_pick()
	var target_index = _outcomes.find(outcome)
	if target_index < 0:
		target_index = 0

	await get_tree().process_frame
	await get_tree().process_frame
	_update_wheel_positions()

	var slot_angle = float(target_index) * (TAU / 4.0)
	var target_angle = -PI / 2.0 - slot_angle + TAU * spins
	_current_angle = 0.0
	_spinning = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_current_angle", target_angle, spin_duration)
	tween.finished.connect(func(): _show_result(outcome))


func _weighted_pick() -> String:
	var total = weight_nothing + weight_shop + weight_double + weight_resurrect
	if total <= 0.0:
		return "nothing"
	var roll = randf() * total
	if roll < weight_nothing:
		return "nothing"
	elif roll < weight_nothing + weight_shop:
		return "shop"
	elif roll < weight_nothing + weight_shop + weight_double:
		return "double"
	return "resurrect"


func _show_result(outcome: String) -> void:
	_spinning = false
	match outcome:
		"shop":
			result_label.text = "Shop appears!"
		"double":
			result_label.text = "Double money!"
		"resurrect":
			result_label.text = "Resurrect!"
		_:
			result_label.text = "Nothing this time."
	outcome_selected.emit(outcome)


func _update_labels() -> void:
	var total = weight_nothing + weight_shop + weight_double + weight_resurrect
	if total <= 0.0:
		total = 1.0
	label_nothing.text = "Nothing %d%%" % int(round((weight_nothing / total) * 100.0))
	label_shop.text = "Shop %d%%" % int(round((weight_shop / total) * 100.0))
	label_double.text = "Double %d%%" % int(round((weight_double / total) * 100.0))
	label_resurrect.text = "Resurrect %d%%" % int(round((weight_resurrect / total) * 100.0))

	label_shop.modulate = Color(0.6, 0.2, 1.0, 1.0)
	label_double.modulate = Color(1.0, 0.55, 0.1, 1.0)
	label_resurrect.modulate = Color(0.2, 1.0, 0.6, 1.0)
