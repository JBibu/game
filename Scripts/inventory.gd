extends Node

signal item_added(item_name: String)
signal item_removed(item_name: String)
signal sword_equipped_changed(equipped: bool)

var items: Dictionary = {}
var sword_equipped: bool = false

func add_item(item_name: String) -> void:
	if not items.has(item_name):
		items[item_name] = 0
	items[item_name] += 1
	item_added.emit(item_name)

	# Auto-equip sword when picked up
	if item_name == "sword":
		equip_sword()

func remove_item(item_name: String) -> bool:
	if has_item(item_name):
		items[item_name] -= 1
		if items[item_name] <= 0:
			items.erase(item_name)
		item_removed.emit(item_name)
		return true
	return false

func has_item(item_name: String) -> bool:
	return items.has(item_name) and items[item_name] > 0

func get_item_count(item_name: String) -> int:
	return items.get(item_name, 0)

func equip_sword() -> void:
	if has_item("sword"):
		sword_equipped = true
		sword_equipped_changed.emit(true)

func unequip_sword() -> void:
	sword_equipped = false
	sword_equipped_changed.emit(false)

func is_sword_equipped() -> bool:
	return sword_equipped and has_item("sword")

func clear() -> void:
	items.clear()
	sword_equipped = false
