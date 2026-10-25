extends SceneTree

## Headless catalog regression checks:
## godot --headless --path . --script res://tests/ArcanaCatalogTests.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var cards: Array[ArcanaCard] = []
	cards.append_array(ArcanaDatabase.all_minor(2))
	cards.append_array(ArcanaDatabase.all_corrupted(2))
	cards.append_array(ArcanaDatabase.all_astral(2))
	cards.append_array(ArcanaDatabase.all_major(2))

	_expect(cards.size() == 61, "Expected 61 catalog cards, found %d." % cards.size(), failures)

	var implemented_effects := [
		"burn_on_hit", "dmg_pct", "speed_pct", "atkspeed_pct", "chill_on_hit",
		"max_hp_flat", "dash_cd_pct", "crit_chance_pct", "thorns_pct", "lifesteal_pct",
		"shard_gain_pct", "pickup_radius_flat", "iron_resolve", "keen_edge", "swift_current",
		"rapid_rhythm", "sure_footing", "predator_eye", "siphon_rune", "briar_aegis",
		"frost_brand", "pyre_mark", "star_tithe", "magnet_core", "focus_lens", "war_drum",
		"windrunner", "frostheart", "sanguine_edge", "thorn_crown", "deep_pockets", "overcharge",
		"reckless_fury", "glass_cannon", "bloodthirst", "chaos_surge", "cursed_hoard",
		"desperate_gambit", "glass_tithe", "fragile_power", "blood_pact", "storm_debt",
		"auto_collect", "floor_shield", "astral_vigor", "void_siphon", "second_skin",
		"astral_edge", "star_eater", "ability_dash_strike", "ability_whirlwind",
		"ability_second_wind", "ability_elemental_infusion", "ability_avatar_form",
		"heart_of_spire", "tempest_core", "titan_soul", "storm_crown", "heart_of_abyss",
	]
	var ids: Dictionary = {}
	var names: Dictionary = {}
	for card in cards:
		_expect(not card.card_id.is_empty(), "%s has no stable card ID." % card.card_name, failures)
		_expect(not card.effect_id.is_empty(), "%s has no effect ID." % card.card_name, failures)
		_expect(implemented_effects.has(card.effect_id), "%s uses an unwired effect ID: %s." % [card.card_name, card.effect_id], failures)
		_expect(not card.description.strip_edges().is_empty(), "%s has no description." % card.card_name, failures)
		_expect(card.unlock_tier in [1, 2], "%s has invalid unlock tier %d." % [card.card_name, card.unlock_tier], failures)
		_expect(not ids.has(card.card_id), "Duplicate card ID: %s." % card.card_id, failures)
		_expect(not names.has(card.card_name), "Duplicate card name: %s." % card.card_name, failures)
		ids[card.card_id] = true
		names[card.card_name] = true
		if card.arcana_type == ArcanaCard.ArcanaType.MAJOR or card.arcana_type == ArcanaCard.ArcanaType.ASTRAL:
			_expect(card.unlock_tier == 2, "%s should unlock at tier 2." % card.card_name, failures)

	_expect(ArcanaDatabase.all_minor(1).size() == 24, "Tier 1 should expose 24 Minor cards.", failures)
	_expect(ArcanaDatabase.all_astral(1).is_empty(), "Astral cards must be tier 2.", failures)
	_expect(ArcanaDatabase.all_major(1).is_empty(), "Major cards must be tier 2.", failures)

	var tier_one_offers := ArcanaDatabase.random_choices(3, 1)
	_expect(tier_one_offers.size() == 3, "Tier 1 should be able to fill three offers.", failures)
	for card in tier_one_offers:
		_expect(card.unlock_tier <= 1, "Tier 1 offered locked card %s." % card.card_name, failures)

	var duplicate_filtered := ArcanaDatabase.random_choices(100, 2, ["ability_whirlwind"])
	for card in duplicate_filtered:
		_expect(not (card.is_active_ability and card.effect_id == "ability_whirlwind"),
			"An already-equipped active ability was offered again.", failures)

	if failures.is_empty():
		print("Arcana catalog checks passed: %d cards, unique IDs/names, valid descriptions and tier gates." % cards.size())
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
