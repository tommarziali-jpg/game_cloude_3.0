extends RefCounted
class_name ArcanaDatabase

## Central data table for every Arcana Card in the game. Kept as plain
## GDScript (rather than dozens of hand-authored .tres files) so the card
## pool is easy to scan, tweak, and extend, and so upgraded/fused copies can
## be created cheaply at runtime via ArcanaCard.make_fused_copy().
##
## Card pools are gated by a "tier" unlocked through meta-progression
## (PlayerStats.unlocked_card_tier) -- see docs/DESIGN.md section on Meta
## Progression. Tier 1 is always available from a fresh save.

static func _card(name_: String, desc: String, type: int, theme: String, effect_id: String,
		value: float, icon: String, active: bool = false, cooldown: float = 8.0, tier: int = -1) -> Dictionary:
	var stable_id := name_.to_snake_case().replace("'", "")
	var resolved_tier := tier if tier >= 1 else (2 if type == ArcanaCard.ArcanaType.MAJOR or type == ArcanaCard.ArcanaType.ASTRAL else 1)
	return {
		"id": stable_id, "name": name_, "desc": desc, "type": type, "theme": theme, "effect_id": effect_id,
		"value": value, "icon": icon, "active": active, "cooldown": cooldown, "tier": resolved_tier,
	}

# ---------------------------------------------------------------------- MINOR
static func _minor_defs() -> Array:
	return [
		_card("Ember Touch", "Your attacks sear enemies for a few seconds.", ArcanaCard.ArcanaType.MINOR, "Fire", "burn_on_hit", 3.0, "card_fire"),
		_card("Cinder Heart", "+12% Damage.", ArcanaCard.ArcanaType.MINOR, "Fire", "dmg_pct", 12.0, "card_fire"),
		_card("Static Step", "+15% Move Speed.", ArcanaCard.ArcanaType.MINOR, "Storm", "speed_pct", 15.0, "card_storm"),
		_card("Charged Strikes", "+10% Attack Speed.", ArcanaCard.ArcanaType.MINOR, "Storm", "atkspeed_pct", 10.0, "card_storm"),
		_card("Frostbite Edge", "+10% chance to briefly chill enemies on hit.", ArcanaCard.ArcanaType.MINOR, "Frost", "chill_on_hit", 10.0, "card_frost"),
		_card("Winter's Ward", "+20 Max Health.", ArcanaCard.ArcanaType.MINOR, "Frost", "max_hp_flat", 20.0, "card_frost"),
		_card("Shade Step", "-15% Dash Cooldown.", ArcanaCard.ArcanaType.MINOR, "Shadow", "dash_cd_pct", -15.0, "card_shadow"),
		_card("Umbral Focus", "+10% Critical Hit Chance.", ArcanaCard.ArcanaType.MINOR, "Shadow", "crit_chance_pct", 10.0, "card_shadow"),
		_card("Thorned Skin", "Reflect 15% of damage taken back at attackers.", ArcanaCard.ArcanaType.MINOR, "Nature", "thorns_pct", 15.0, "card_nature"),
		_card("Vital Bloom", "+12% Lifesteal on all attacks.", ArcanaCard.ArcanaType.MINOR, "Nature", "lifesteal_pct", 12.0, "card_nature"),
		_card("Hungry Void", "+20% Star Shards from all sources.", ArcanaCard.ArcanaType.MINOR, "Void", "shard_gain_pct", 20.0, "card_void"),
		_card("Void Pull", "Greatly increases pickup magnetism range.", ArcanaCard.ArcanaType.MINOR, "Void", "pickup_radius_flat", 90.0, "card_void"),
		_card("Iron Resolve", "+25 Max Health.", ArcanaCard.ArcanaType.MINOR, "Nature", "iron_resolve", 25.0, "card_nature"),
		_card("Keen Edge", "+8% Damage.", ArcanaCard.ArcanaType.MINOR, "Fire", "keen_edge", 8.0, "card_fire"),
		_card("Swift Current", "+8% Move Speed.", ArcanaCard.ArcanaType.MINOR, "Storm", "swift_current", 8.0, "card_storm"),
		_card("Rapid Rhythm", "+8% Attack Speed.", ArcanaCard.ArcanaType.MINOR, "Storm", "rapid_rhythm", 8.0, "card_storm"),
		_card("Sure Footing", "-10% Dash Cooldown.", ArcanaCard.ArcanaType.MINOR, "Shadow", "sure_footing", -10.0, "card_shadow"),
		_card("Predator Eye", "+5% Critical Hit Chance.", ArcanaCard.ArcanaType.MINOR, "Shadow", "predator_eye", 5.0, "card_shadow"),
		_card("Siphon Rune", "+5% Lifesteal on attacks.", ArcanaCard.ArcanaType.MINOR, "Blood", "siphon_rune", 5.0, "card_nature"),
		_card("Briar Aegis", "Reflect 10% of damage taken back at attackers.", ArcanaCard.ArcanaType.MINOR, "Nature", "briar_aegis", 10.0, "card_nature"),
		_card("Frost Brand", "Attacks have an 8% chance to chill enemies for 2 seconds.", ArcanaCard.ArcanaType.MINOR, "Frost", "frost_brand", 8.0, "card_frost"),
		_card("Pyre Mark", "Attacks burn enemies for 2 damage per second for 3 seconds.", ArcanaCard.ArcanaType.MINOR, "Fire", "pyre_mark", 2.0, "card_fire"),
		_card("Star Tithe", "+10% Star Shards from all sources.", ArcanaCard.ArcanaType.MINOR, "Void", "star_tithe", 10.0, "card_void"),
		_card("Magnet Core", "+45 pickup magnet range.", ArcanaCard.ArcanaType.MINOR, "Void", "magnet_core", 45.0, "card_void"),
		_card("Focus Lens", "+8% Critical Hit Chance.", ArcanaCard.ArcanaType.MINOR, "Shadow", "focus_lens", 8.0, "card_shadow", false, 8.0, 2),
		_card("War Drum", "+12% Attack Speed.", ArcanaCard.ArcanaType.MINOR, "Storm", "war_drum", 12.0, "card_storm", false, 8.0, 2),
		_card("Windrunner", "+12% Move Speed.", ArcanaCard.ArcanaType.MINOR, "Storm", "windrunner", 12.0, "card_storm", false, 8.0, 2),
		_card("Frostheart", "+35 Max Health.", ArcanaCard.ArcanaType.MINOR, "Frost", "frostheart", 35.0, "card_frost", false, 8.0, 2),
		_card("Sanguine Edge", "+8% Lifesteal on attacks.", ArcanaCard.ArcanaType.MINOR, "Blood", "sanguine_edge", 8.0, "card_nature", false, 8.0, 2),
		_card("Thorn Crown", "Reflect 15% of damage taken back at attackers.", ArcanaCard.ArcanaType.MINOR, "Nature", "thorn_crown", 15.0, "card_nature", false, 8.0, 2),
		_card("Deep Pockets", "+15% Star Shards from all sources.", ArcanaCard.ArcanaType.MINOR, "Void", "deep_pockets", 15.0, "card_void", false, 8.0, 2),
		_card("Overcharge", "+10% Damage.", ArcanaCard.ArcanaType.MINOR, "Fire", "overcharge", 10.0, "card_fire", false, 8.0, 2),
	]

# ------------------------------------------------------------------ CORRUPTED
static func _corrupted_defs() -> Array:
	return [
		_card("Reckless Fury", "+30% Damage, but -20% Max Health.", ArcanaCard.ArcanaType.CORRUPTED, "Blood", "reckless_fury", 30.0, "card_corrupted"),
		_card("Glass Cannon", "+45% Critical Damage, but you take +15% damage.", ArcanaCard.ArcanaType.CORRUPTED, "Blood", "glass_cannon", 45.0, "card_corrupted"),
		_card("Bloodthirst", "+25% Lifesteal, but -15% Move Speed.", ArcanaCard.ArcanaType.CORRUPTED, "Blood", "bloodthirst", 25.0, "card_corrupted"),
		_card("Chaos Surge", "+25% Attack Speed, but +25% Dash Cooldown.", ArcanaCard.ArcanaType.CORRUPTED, "Storm", "chaos_surge", 25.0, "card_corrupted"),
		_card("Cursed Hoard", "+40% Star Shards, but enemies have +15% Health.", ArcanaCard.ArcanaType.CORRUPTED, "Void", "cursed_hoard", 40.0, "card_corrupted"),
		_card("Desperate Gambit", "+25% Damage while below 50% Health.", ArcanaCard.ArcanaType.CORRUPTED, "Blood", "desperate_gambit", 25.0, "card_corrupted"),
		_card("Glass Tithe", "+25% Star Shards, but enemies have +10% Health.", ArcanaCard.ArcanaType.CORRUPTED, "Void", "glass_tithe", 25.0, "card_corrupted"),
		_card("Fragile Power", "+20% Damage, but you take +10% damage.", ArcanaCard.ArcanaType.CORRUPTED, "Blood", "fragile_power", 20.0, "card_corrupted"),
		_card("Blood Pact", "+20% Lifesteal, but -15 Max Health.", ArcanaCard.ArcanaType.CORRUPTED, "Blood", "blood_pact", 20.0, "card_corrupted"),
		_card("Storm Debt", "+20% Attack Speed, but +15% Dash Cooldown.", ArcanaCard.ArcanaType.CORRUPTED, "Storm", "storm_debt", 20.0, "card_corrupted"),
	]

# --------------------------------------------------------------------- ASTRAL
static func _astral_defs() -> Array:
	return [
		_card("Astral Magnetism", "Pickups fly to you from anywhere on the floor.", ArcanaCard.ArcanaType.ASTRAL, "Void", "auto_collect", 1.0, "card_astral", false, 8.0, 2),
		_card("Star Shield", "Start each floor with a shield that blocks one hit.", ArcanaCard.ArcanaType.ASTRAL, "Frost", "floor_shield", 1.0, "card_astral", false, 8.0, 2),
		_card("Astral Bounty", "+60% Star Shards from all sources.", ArcanaCard.ArcanaType.ASTRAL, "Void", "shard_gain_pct", 60.0, "card_astral", false, 8.0, 2),
		_card("Temporal Echo", "-40% Dash Cooldown.", ArcanaCard.ArcanaType.ASTRAL, "Storm", "dash_cd_pct", -40.0, "card_astral", false, 8.0, 2),
		_card("Astral Vigor", "+30 Max Health and +15% Damage.", ArcanaCard.ArcanaType.ASTRAL, "Fire", "astral_vigor", 30.0, "card_astral", false, 8.0, 2),
		_card("Void Siphon", "Pickups fly to you from anywhere on the floor.", ArcanaCard.ArcanaType.ASTRAL, "Void", "void_siphon", 1.0, "card_astral", false, 8.0, 2),
		_card("Second Skin", "Start each floor with a shield that blocks one hit.", ArcanaCard.ArcanaType.ASTRAL, "Frost", "second_skin", 1.0, "card_astral", false, 8.0, 2),
		_card("Astral Edge", "+20% Damage.", ArcanaCard.ArcanaType.ASTRAL, "Fire", "astral_edge", 20.0, "card_astral", false, 8.0, 2),
		_card("Star Eater", "Pickups fly to you from anywhere; gain +25% Star Shards.", ArcanaCard.ArcanaType.ASTRAL, "Void", "star_eater", 25.0, "card_astral", false, 8.0, 2),
	]

# ----------------------------------------------------------------------- MAJOR
static func _major_defs() -> Array:
	return [
		_card("Arcana of the Breaking Wave", "Your dash erupts, damaging nearby enemies.", ArcanaCard.ArcanaType.MAJOR, "Storm", "ability_dash_strike", 0.0, "card_major", false, 8.0, 2),
		_card("Arcana of the Cyclone", "Channel a spinning strike that damages everything nearby.", ArcanaCard.ArcanaType.MAJOR, "Storm", "ability_whirlwind", 0.0, "card_major", true, 8.0),
		_card("Arcana of Renewal", "Instantly heal and become briefly untouchable.", ArcanaCard.ArcanaType.MAJOR, "Nature", "ability_second_wind", 0.0, "card_major", true, 10.0),
		_card("Arcana of Embers", "Your attacks sear everything they touch for a time.", ArcanaCard.ArcanaType.MAJOR, "Fire", "ability_elemental_infusion", 0.0, "card_major", true, 10.0),
		_card("Arcana of Ascension", "Become briefly unstoppable: immune and far stronger.", ArcanaCard.ArcanaType.MAJOR, "Void", "ability_avatar_form", 0.0, "card_major", true, 14.0),
		_card("Heart of the Spire", "+60 Max Health and +15% Damage.", ArcanaCard.ArcanaType.MAJOR, "Blood", "heart_of_spire", 0.0, "card_major"),
		_card("Tempest Core", "+25% Attack Speed and +25% Move Speed.", ArcanaCard.ArcanaType.MAJOR, "Storm", "tempest_core", 0.0, "card_major", false, 8.0, 2),
		_card("Titan Soul", "+50 Max Health and +10% Damage.", ArcanaCard.ArcanaType.MAJOR, "Nature", "titan_soul", 50.0, "card_major", false, 8.0, 2),
		_card("Storm Crown", "+15% Move Speed and +15% Attack Speed.", ArcanaCard.ArcanaType.MAJOR, "Storm", "storm_crown", 15.0, "card_major", false, 8.0, 2),
		_card("Heart of the Abyss", "+40 Max Health and +20% Damage.", ArcanaCard.ArcanaType.MAJOR, "Void", "heart_of_abyss", 40.0, "card_major", false, 8.0, 2),
	]

static func _build(def: Dictionary) -> ArcanaCard:
	var c := ArcanaCard.new()
	c.card_id = def["id"]
	c.unlock_tier = def["tier"]
	c.card_name = def["name"]
	c.description = def["desc"]
	c.arcana_type = def["type"]
	c.theme = def["theme"]
	c.effect_id = def["effect_id"]
	c.value = def["value"]
	c.icon_kind = def["icon"]
	c.is_active_ability = def["active"]
	c.ability_cooldown = def["cooldown"]
	return c

static func all_minor(tier: int = 1) -> Array[ArcanaCard]:
	var out: Array[ArcanaCard] = []
	for d in _minor_defs():
		if d["tier"] <= tier:
			out.append(_build(d))
	return out

static func all_corrupted(tier: int = 1) -> Array[ArcanaCard]:
	var out: Array[ArcanaCard] = []
	for d in _corrupted_defs():
		if d["tier"] <= tier:
			out.append(_build(d))
	return out

static func all_astral(tier: int = 1) -> Array[ArcanaCard]:
	var out: Array[ArcanaCard] = []
	for d in _astral_defs():
		if d["tier"] <= tier:
			out.append(_build(d))
	return out

static func all_major(tier: int = 1) -> Array[ArcanaCard]:
	var out: Array[ArcanaCard] = []
	for d in _major_defs():
		if d["tier"] <= tier:
			out.append(_build(d))
	return out

## Weighted random draw used by Reward Altars / Shops: mostly Minor, sometimes
## Corrupted, rarely Astral/Major. `exclude_active_duplicates` avoids offering
## a second copy of an active Major Arcana the player already has equipped.
static func random_choices(count: int, tier: int, already_active_ids: Array = []) -> Array[ArcanaCard]:
	var pool: Array[ArcanaCard] = []
	pool.append_array(all_minor(tier))
	pool.append_array(all_minor(tier))  # weight minor higher
	pool.append_array(all_corrupted(tier))
	if tier >= 2:
		pool.append_array(all_astral(tier))
	pool.append_array(all_major(tier))

	pool = pool.filter(func(c): return not (c.is_active_ability and already_active_ids.has(c.effect_id)))
	pool.shuffle()

	var out: Array[ArcanaCard] = []
	var used_names: Array[String] = []
	for c in pool:
		if out.size() >= count:
			break
		if used_names.has(c.card_name):
			continue
		used_names.append(c.card_name)
		out.append(c)
	return out
