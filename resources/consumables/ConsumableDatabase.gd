extends RefCounted
class_name ConsumableDatabase

## Central data table for every Consumable. Found in chests/reward altars,
## shops (Rest Chambers / Special Shops), and occasional mob drops. Used by
## pressing the Consumable key; stacks in inventory by item id.

static func _item(name_: String, desc: String, effect: int, value: float, duration: float, cost: int, icon: String, purchasable: bool = true) -> Dictionary:
	return {"name": name_, "desc": desc, "effect": effect, "value": value, "duration": duration, "cost": cost, "icon": icon, "purchasable": purchasable}

static func _defs() -> Array:
	return [
		_item("Health Draught", "Instantly restores 50% of your max health.", Consumable.ConsumableEffect.HEAL, 0.5, 0.0, 18, "potion_heal"),
		_item("Vial of Might", "+15% Damage for 45 seconds.", Consumable.ConsumableEffect.STRENGTH_BUFF, 15.0, 45.0, 22, "potion_str"),
		_item("Vial of Haste", "+35% Move Speed for 30 seconds.", Consumable.ConsumableEffect.SPEED_BUFF, 0.35, 30.0, 22, "potion_speed"),
		_item("Vial of Fortitude", "+40 Max Health for 45 seconds.", Consumable.ConsumableEffect.FORTITUDE_BUFF, 40.0, 45.0, 25, "potion_fortitude"),
		_item("Warding Shield", "Grants a shield that blocks the next hit you take.", Consumable.ConsumableEffect.SHIELD, 1.0, 0.0, 30, "potion_shield"),
		_item("Unstable Shard Cluster", "Bursts into a windfall of Star Shards.", Consumable.ConsumableEffect.SHARD_BURST, 20.0, 0.0, 0, "potion_shard", false),
	]

static func _build(def: Dictionary) -> Consumable:
	var c := Consumable.new()
	c.consumable_name = def["name"]
	c.description = def["desc"]
	c.effect = def["effect"]
	c.value = def["value"]
	c.duration = def["duration"]
	c.cost = def["cost"]
	c.icon_kind = def["icon"]
	return c

static func all() -> Array[Consumable]:
	var out: Array[Consumable] = []
	for d in _defs():
		out.append(_build(d))
	return out

static func all_purchasable() -> Array[Consumable]:
	var out: Array[Consumable] = []
	for d in _defs():
		if d["purchasable"]:
			out.append(_build(d))
	return out

static func random_drop() -> Consumable:
	var defs := _defs()
	return _build(defs[randi() % defs.size()])

## Stable id used as the inventory dictionary key (so we don't rely on a
## Resource's object identity, which changes every time we _build() a copy).
static func id_for(c: Consumable) -> String:
	return c.consumable_name
