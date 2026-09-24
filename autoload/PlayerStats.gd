extends Node

## Single source of truth for the player's progression.

signal health_changed(current: float, max_hp: float)
signal star_shards_changed(amount: int)
signal arcana_changed
signal artifacts_changed
signal consumables_changed
signal card_acquired(card: ArcanaCard)
signal artifact_acquired(artifact: Artifact)
signal arcana_slot_gained(new_count: int)

const SAVE_PATH := "user://savegame.json"

var deepest_floor_reached: int = 0
var total_runs: int = 0
var bosses_defeated_ever: int = 0
var unlocked_card_tier: int = 1

const BASE_MAX_HEALTH := 100.0
const BASE_DAMAGE := 10.0
const BASE_DASH_COOLDOWN := 0.6
const STARTING_ARCANA_SLOTS := 3

var star_shards: int = 0
var arcana_slot_count: int = STARTING_ARCANA_SLOTS
var equipped_arcana: Array = []
var owned_artifacts: Array[Artifact] = []
var consumable_inventory: Dictionary = {}
var current_health: float = BASE_MAX_HEALTH
var shield_charges: int = 0
var revive_used: bool = false

var temp_dmg_pct: float = 0.0
var temp_dmg_timer: float = 0.0
var temp_speed_pct: float = 0.0
var temp_speed_timer: float = 0.0
var temp_hp_flat: float = 0.0
var temp_hp_timer: float = 0.0

# Sir Gideon's Rust Cloud temporarily increases damage taken, representing
# corroded armor/defenses. It is intentionally kept in PlayerStats so every
# damage source respects the same defense reduction.
var rust_defense_reduction_pct: float = 0.0
var rust_defense_timer: float = 0.0

func _ready() -> void:
	equipped_arcana.resize(arcana_slot_count)
	load_game()

func _process(delta: float) -> void:
	if temp_dmg_timer > 0.0:
		temp_dmg_timer -= delta
		if temp_dmg_timer <= 0.0:
			temp_dmg_pct = 0.0
	if temp_speed_timer > 0.0:
		temp_speed_timer -= delta
		if temp_speed_timer <= 0.0:
			temp_speed_pct = 0.0
	if temp_hp_timer > 0.0:
		temp_hp_timer -= delta
		if temp_hp_timer <= 0.0:
			temp_hp_flat = 0.0
		health_changed.emit(current_health, max_health())
	if rust_defense_timer > 0.0:
		rust_defense_timer -= delta
		if rust_defense_timer <= 0.0:
			rust_defense_reduction_pct = 0.0

func _effect_value(id: String) -> float:
	var total := 0.0
	for c in equipped_arcana:
		if c != null and c.effect_id == id:
			total += c.value
	for a in owned_artifacts:
		if a.effect_id == id:
			total += a.value
	return total

func _effect_count(id: String) -> int:
	var n := 0
	for c in equipped_arcana:
		if c != null and c.effect_id == id:
			n += 1
	for a in owned_artifacts:
		if a.effect_id == id:
			n += 1
	return n

func has_effect(id: String) -> bool:
	return _effect_count(id) > 0

func theme_count(theme: String) -> int:
	var n := 0
	for c in equipped_arcana:
		if c != null and c.theme == theme:
			n += 1
	return n

func max_health() -> float:
	var v := BASE_MAX_HEALTH
	v += _effect_value("max_hp_flat")
	v += float(_effect_count("heart_of_spire")) * 60.0
	v += float(_effect_count("astral_vigor")) * 30.0
	v += float(_effect_count("heart_of_warden")) * 80.0
	v -= BASE_MAX_HEALTH * 0.20 * float(_effect_count("reckless_fury"))
	v += temp_hp_flat
	var nature := theme_count("Nature")
	if nature >= 3:
		v += 25.0
	elif nature >= 2:
		v += 10.0
	return max(20.0, v)

func damage_multiplier() -> float:
	var pct := _effect_value("dmg_pct")
	pct += float(_effect_count("reckless_fury")) * 30.0
	pct += float(_effect_count("astral_vigor")) * 15.0
	pct += float(_effect_count("heart_of_spire")) * 15.0
	pct += float(_effect_count("heart_of_warden")) * 10.0
	pct += temp_dmg_pct
	if current_health < max_health() * 0.5:
		pct += float(_effect_count("desperate_gambit")) * 25.0
	var fire := theme_count("Fire")
	if fire >= 3:
		pct += 20.0
	elif fire >= 2:
		pct += 8.0
	return 1.0 + pct / 100.0

func damage_taken_multiplier() -> float:
	var pct := float(_effect_count("glass_cannon")) * 15.0
	pct += rust_defense_reduction_pct
	return 1.0 + pct / 100.0

func apply_rust_defense_reduction(percent: float, duration: float) -> void:
	rust_defense_reduction_pct = max(rust_defense_reduction_pct, percent * 100.0)
	rust_defense_timer = max(rust_defense_timer, duration)

func speed_multiplier() -> float:
	var pct := _effect_value("speed_pct")
	pct -= float(_effect_count("bloodthirst")) * 15.0
	pct += float(_effect_count("tempest_core")) * 25.0
	pct += temp_speed_pct
	var storm := theme_count("Storm")
	if storm >= 3:
		pct += 15.0
	elif storm >= 2:
		pct += 6.0
	return max(0.3, 1.0 + pct / 100.0)

func attack_speed_multiplier() -> float:
	var pct := _effect_value("atkspeed_pct")
	pct += float(_effect_count("chaos_surge")) * 25.0
	pct += float(_effect_count("tempest_core")) * 25.0
	return max(0.3, 1.0 + pct / 100.0)

func dash_cooldown() -> float:
	var pct := _effect_value("dash_cd_pct")
	pct += float(_effect_count("chaos_surge")) * 25.0
	var mult: float = max(0.2, 1.0 + pct / 100.0)
	return max(0.12, BASE_DASH_COOLDOWN * mult)

func crit_chance() -> float:
	return clamp(_effect_value("crit_chance_pct") / 100.0, 0.0, 0.9)

func crit_multiplier() -> float:
	return 1.5 + float(_effect_count("glass_cannon")) * 0.45

func lifesteal_pct() -> float:
	var pct := _effect_value("lifesteal_pct")
	pct += float(_effect_count("bloodthirst")) * 25.0
	return pct / 100.0

func thorns_pct() -> float:
	return _effect_value("thorns_pct") / 100.0

func shard_gain_multiplier() -> float:
	var pct := _effect_value("shard_gain_pct")
	pct += float(_effect_count("cursed_hoard")) * 40.0
	pct += float(_effect_count("star_compass")) * 30.0
	var void_ct := theme_count("Void")
	if void_ct >= 3:
		pct += 25.0
	elif void_ct >= 2:
		pct += 10.0
	return 1.0 + pct / 100.0

func enemy_hp_multiplier() -> float:
	return 1.0 + float(_effect_count("cursed_hoard")) * 0.15

func pickup_radius_bonus() -> float:
	return _effect_value("pickup_radius_flat")

func has_auto_collect() -> bool:
	return has_effect("auto_collect") or has_effect("star_compass")

func burn_on_hit_value() -> float:
	return _effect_value("burn_on_hit")

func chill_chance() -> float:
	return clamp(_effect_value("chill_on_hit") / 100.0, 0.0, 1.0)

func active_ability_card() -> ArcanaCard:
	for c in equipped_arcana:
		if c != null and c.is_active_ability:
			return c
	return null

func add_star_shards(amount: int) -> void:
	var final_amount: int = int(round(float(amount) * shard_gain_multiplier()))
	star_shards += final_amount
	star_shards_changed.emit(star_shards)

func spend_star_shards(amount: int) -> bool:
	if star_shards < amount:
		return false
	star_shards -= amount
	star_shards_changed.emit(star_shards)
	return true

func take_damage(amount: float) -> void:
	if shield_charges > 0:
		shield_charges -= 1
		return
	var final_amount: float = amount * damage_taken_multiplier()
	current_health = max(0.0, current_health - final_amount)
	health_changed.emit(current_health, max_health())

func heal(amount: float) -> void:
	current_health = min(max_health(), current_health + amount)
	health_changed.emit(current_health, max_health())

func try_revive() -> bool:
	if has_effect("revive_once") and not revive_used:
		revive_used = true
		current_health = max_health() * 0.5
		health_changed.emit(current_health, max_health())
		return true
	return false

func is_dead() -> bool:
	return current_health <= 0.0

func grant_shield_charge(charges: int = 1) -> void:
	shield_charges = max(shield_charges, charges)

func refresh_floor_shield() -> void:
	if has_effect("floor_shield"):
		grant_shield_charge(1)

func equip_arcana(card: ArcanaCard, slot_index: int) -> void:
	if slot_index < 0 or slot_index >= equipped_arcana.size():
		return
	equipped_arcana[slot_index] = card
	arcana_changed.emit()

func first_empty_slot() -> int:
	for i in range(equipped_arcana.size()):
		if equipped_arcana[i] == null:
			return i
	return -1

func add_card_to_first_empty_slot(card: ArcanaCard) -> bool:
	var idx := first_empty_slot()
	if idx == -1:
		return false
	equip_arcana(card, idx)
	card_acquired.emit(card)
	return true

func remove_arcana(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= equipped_arcana.size():
		return
	equipped_arcana[slot_index] = null
	arcana_changed.emit()

func fuse_arcana(slot_a: int, slot_b: int) -> bool:
	if slot_a == slot_b:
		return false
	if slot_a < 0 or slot_a >= equipped_arcana.size() or slot_b < 0 or slot_b >= equipped_arcana.size():
		return false
	var a: ArcanaCard = equipped_arcana[slot_a]
	var b: ArcanaCard = equipped_arcana[slot_b]
	if a == null or b == null or a.theme != b.theme:
		return false
	var fused := a.make_fused_copy()
	equipped_arcana[slot_a] = fused
	equipped_arcana[slot_b] = null
	arcana_changed.emit()
	return true

func gain_arcana_slot() -> void:
	arcana_slot_count += 1
	equipped_arcana.append(null)
	arcana_slot_gained.emit(arcana_slot_count)

func add_artifact(artifact: Artifact) -> void:
	owned_artifacts.append(artifact)
	artifacts_changed.emit()
	artifact_acquired.emit(artifact)
	health_changed.emit(current_health, max_health())

func add_consumable(item: Consumable, count: int = 1) -> void:
	var id := ConsumableDatabase.id_for(item)
	if consumable_inventory.has(id):
		consumable_inventory[id]["count"] += count
	else:
		consumable_inventory[id] = {"item": item, "count": count}
	consumables_changed.emit()

func use_consumable(id: String) -> bool:
	if not consumable_inventory.has(id):
		return false
	var entry: Dictionary = consumable_inventory[id]
	var item: Consumable = entry["item"]
	_apply_consumable_effect(item)
	entry["count"] -= 1
	if entry["count"] <= 0:
		consumable_inventory.erase(id)
		consumables_changed.emit()
	return true

func use_best_consumable() -> bool:
	for id in consumable_inventory.keys():
		var entry: Dictionary = consumable_inventory[id]
		var item: Consumable = entry["item"]
		if item.effect == Consumable.ConsumableEffect.HEAL and current_health < max_health():
			return use_consumable(id)
	for id in consumable_inventory.keys():
		return use_consumable(id)
	return false

func _apply_consumable_effect(item: Consumable) -> void:
	match item.effect:
		Consumable.ConsumableEffect.HEAL:
			heal(max_health() * item.value)
		Consumable.ConsumableEffect.STRENGTH_BUFF:
			temp_dmg_pct = max(temp_dmg_pct, item.value)
			temp_dmg_timer = max(temp_dmg_timer, item.duration)
		Consumable.ConsumableEffect.SPEED_BUFF:
			temp_speed_pct = max(temp_speed_pct, item.value * 100.0)
			temp_speed_timer = max(temp_speed_timer, item.duration)
		Consumable.ConsumableEffect.FORTITUDE_BUFF:
			temp_hp_flat = max(temp_hp_flat, item.value)
			temp_hp_timer = max(temp_hp_timer, item.duration)
			current_health += item.value
			health_changed.emit(current_health, max_health())
		Consumable.ConsumableEffect.SHARD_BURST:
			add_star_shards(int(item.value))
		Consumable.ConsumableEffect.SHIELD:
			grant_shield_charge(1)

func reset_for_new_run() -> void:
	star_shards = 0
	arcana_slot_count = STARTING_ARCANA_SLOTS
	equipped_arcana.clear()
	equipped_arcana.resize(arcana_slot_count)
	owned_artifacts.clear()
	consumable_inventory.clear()
	shield_charges = 0
	revive_used = false
	temp_dmg_pct = 0.0
	temp_dmg_timer = 0.0
	temp_speed_pct = 0.0
	temp_speed_timer = 0.0
	temp_hp_flat = 0.0
	temp_hp_timer = 0.0
	rust_defense_reduction_pct = 0.0
	rust_defense_timer = 0.0
	current_health = max_health()
	health_changed.emit(current_health, max_health())
	star_shards_changed.emit(star_shards)
	arcana_changed.emit()
	artifacts_changed.emit()
	consumables_changed.emit()

func on_boss_defeated() -> void:
	bosses_defeated_ever += 1
	gain_arcana_slot()
	_check_meta_unlocks()
	save_game()

func on_run_ended(floor_reached: int) -> void:
	deepest_floor_reached = max(deepest_floor_reached, floor_reached)
	total_runs += 1
	_check_meta_unlocks()
	current_health = max_health()
	save_game()

func _check_meta_unlocks() -> void:
	if deepest_floor_reached >= 15 and unlocked_card_tier < 2:
		unlocked_card_tier = 2

func save_game() -> void:
	var data := {
		"deepest_floor_reached": deepest_floor_reached,
		"total_runs": total_runs,
		"bosses_defeated_ever": bosses_defeated_ever,
		"unlocked_card_tier": unlocked_card_tier,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	deepest_floor_reached = parsed.get("deepest_floor_reached", deepest_floor_reached)
	total_runs = parsed.get("total_runs", total_runs)
	bosses_defeated_ever = parsed.get("bosses_defeated_ever", bosses_defeated_ever)
	unlocked_card_tier = parsed.get("unlocked_card_tier", unlocked_card_tier)
	current_health = max_health()
