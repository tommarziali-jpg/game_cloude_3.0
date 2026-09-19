extends RefCounted
class_name ArtifactDatabase

## Central data table for every Artifact. Found in Artifact Rooms, guaranteed
## from boss kills, and occasionally offered in Special Shops.

static func _artifact(name_: String, desc: String, rarity: int, effect_id: String, value: float, icon: String) -> Dictionary:
	return {"name": name_, "desc": desc, "rarity": rarity, "effect_id": effect_id, "value": value, "icon": icon}

static func _defs() -> Array:
	return [
		_artifact("Warden's Charm", "+15 Max Health.", Artifact.Rarity.COMMON, "max_hp_flat", 15.0, "artifact_common"),
		_artifact("Quickstep Boots", "+10% Move Speed.", Artifact.Rarity.COMMON, "speed_pct", 10.0, "artifact_common"),
		_artifact("Sharpened Whetstone", "+8% Damage.", Artifact.Rarity.COMMON, "dmg_pct", 8.0, "artifact_common"),
		_artifact("Lucky Coin", "+15% Star Shards from all sources.", Artifact.Rarity.COMMON, "shard_gain_pct", 15.0, "artifact_common"),
		_artifact("Vampiric Locket", "+15% Lifesteal on all attacks.", Artifact.Rarity.RARE, "lifesteal_pct", 15.0, "artifact_rare"),
		_artifact("Thornmail Fragment", "Reflect 20% of damage taken back at attackers.", Artifact.Rarity.RARE, "thorns_pct", 20.0, "artifact_rare"),
		_artifact("Adrenaline Vial", "+15% Attack Speed.", Artifact.Rarity.RARE, "atkspeed_pct", 15.0, "artifact_rare"),
		_artifact("Cracked Hourglass", "-20% Dash Cooldown.", Artifact.Rarity.RARE, "dash_cd_pct", -20.0, "artifact_rare"),
		_artifact("Phoenix Ash", "Revive once per run with 50% Health when you would die.", Artifact.Rarity.LEGENDARY, "revive_once", 0.5, "artifact_legendary"),
		_artifact("Heart of the Warden", "+80 Max Health and +10% Damage.", Artifact.Rarity.LEGENDARY, "heart_of_warden", 80.0, "artifact_legendary"),
		_artifact("Star Compass", "Pickups fly to you from anywhere, +30% Star Shards.", Artifact.Rarity.LEGENDARY, "star_compass", 30.0, "artifact_legendary"),
	]

static func _build(def: Dictionary) -> Artifact:
	var a := Artifact.new()
	a.artifact_name = def["name"]
	a.description = def["desc"]
	a.rarity = def["rarity"]
	a.effect_id = def["effect_id"]
	a.value = def["value"]
	a.icon_kind = def["icon"]
	return a

static func all_by_rarity(rarity: int) -> Array[Artifact]:
	var out: Array[Artifact] = []
	for d in _defs():
		if d["rarity"] == rarity:
			out.append(_build(d))
	return out

static func random_one(rarity: int = -1) -> Artifact:
	var defs := _defs()
	if rarity != -1:
		defs = defs.filter(func(d): return d["rarity"] == rarity)
	if defs.is_empty():
		return null
	return _build(defs[randi() % defs.size()])

## Weighted rarity roll used by boss drops / artifact rooms: mostly common,
## sometimes rare, rarely legendary.
static func random_weighted() -> Artifact:
	var roll := randf()
	if roll < 0.55:
		return random_one(Artifact.Rarity.COMMON)
	elif roll < 0.9:
		return random_one(Artifact.Rarity.RARE)
	else:
		return random_one(Artifact.Rarity.LEGENDARY)
