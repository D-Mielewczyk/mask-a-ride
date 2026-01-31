# gdlint:ignore = class-definitions-order
extends Resource
class_name ShopUpgrade

@export var id := ""
@export var display_name := "Upgrade"
@export var description := "Description"
@export var price := 100
@export var icon: Texture2D
@export_enum("common", "rare", "epic", "legendary") var rarity := "common"
@export var effect_id := ""
@export var requires_ids: PackedStringArray = []
@export var stat_name := ""
@export_enum("add", "mul") var apply_mode := "add"
@export var stat_value := 0.0

var bought := false


func can_apply_to(player: Node) -> bool:
	return stat_name != "" and player != null and player.has_property(stat_name)


func apply_to(player: Node) -> void:
	if not can_apply_to(player):
		return
	var current = player.get(stat_name)
	if apply_mode == "mul":
		player.set(stat_name, current * stat_value)
	else:
		player.set(stat_name, current + stat_value)
