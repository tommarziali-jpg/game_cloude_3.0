extends Node
class_name WaveData

## Pure-data helper: decides which enemies spawn on a given floor/wave, and
## which boss owns a given boss floor. A boss appears every 5th floor,
## rotating through all 10 Wardens forever (see docs/STORY.md Bestiary), so
## each boss's own minions show up in the regular waves on the floors
## leading up to "their" boss floor.

const GRUNT := "res://scenes/enemies/Grunt.tscn"

# --- Act I minions (Ember Matriarch) ---
const PIGLET := "res://scenes/enemies/TuskedPiglet.tscn"
const HOG := "res://scenes/enemies/EmberHog.tscn"

# --- Act II minions (Hollow Chorister) ---
const WRAITH := "res://scenes/enemies/ChainWraith.tscn"
const LARVA := "res://scenes/enemies/EchoLarva.tscn"

# --- Act III minions (Umbral Warden) ---
const SHADE := "res://scenes/enemies/ShadeClone.tscn"
const MOTH := "res://scenes/enemies/VoidMoth.tscn"

# --- Act IV minions (Glass Tyrant) ---
const MIRROR_WRAITH := "res://scenes/enemies/MirrorWraith.tscn"
const GLARE_WISP := "res://scenes/enemies/GlareWisp.tscn"
const VAIN_DUELIST := "res://scenes/enemies/VainDuelist.tscn"

# --- Act V minions (Plague Cantor) ---
const BLOAT_ROACH := "res://scenes/enemies/BloatRoach.tscn"
const SPORE_DRIFTER := "res://scenes/enemies/SporeDrifter.tscn"
const HOLLOW_BEGGAR := "res://scenes/enemies/HollowBeggar.tscn"

# --- Act VI minions (Iron Inquisitor) ---
const BRAND_ACOLYTE := "res://scenes/enemies/BrandAcolyte.tscn"
const CHAIN_WARDEN := "res://scenes/enemies/ChainWarden.tscn"
const ASHEN_ZEALOT := "res://scenes/enemies/AshenZealot.tscn"

# --- Act VII minions (Drowned Choir) ---
const DROWNED_HUSK := "res://scenes/enemies/DrownedHusk.tscn"
const RIPTIDE_EEL := "res://scenes/enemies/RiptideEel.tscn"
const WAILING_GULL := "res://scenes/enemies/WailingGull.tscn"

# --- Act VIII minions (Starving King) ---
const STARVED_WRETCH := "res://scenes/enemies/StarvedWretch.tscn"
const CARRION_CROW := "res://scenes/enemies/CarrionCrow.tscn"
const FAMINE_HUSK := "res://scenes/enemies/FamineHusk.tscn"

# --- Act IX minions (Static Sovereign) ---
const SPARK_WISP := "res://scenes/enemies/SparkWisp.tscn"
const THUNDER_HAWK := "res://scenes/enemies/ThunderHawk.tscn"
const STATIC_DRONE := "res://scenes/enemies/StaticDrone.tscn"

# --- Act X minions (Grief Weaver) ---
const BROODLING := "res://scenes/enemies/Broodling.tscn"
const WEEPING_SHADE := "res://scenes/enemies/WeepingShade.tscn"
const SILK_STALKER := "res://scenes/enemies/SilkStalker.tscn"

const BOSS_MATRIARCH := "res://scenes/bosses/EmberMatriarch.tscn"
const BOSS_CHORISTER := "res://scenes/bosses/HollowChorister.tscn"
const BOSS_WARDEN := "res://scenes/bosses/UmbralWarden.tscn"
const BOSS_TYRANT := "res://scenes/bosses/GlassTyrant.tscn"
const BOSS_CANTOR := "res://scenes/bosses/PlagueCantor.tscn"
const BOSS_INQUISITOR := "res://scenes/bosses/IronInquisitor.tscn"
const BOSS_CHOIR := "res://scenes/bosses/DrownedChoir.tscn"
const BOSS_KING := "res://scenes/bosses/StarvingKing.tscn"
const BOSS_SOVEREIGN := "res://scenes/bosses/StaticSovereign.tscn"
const BOSS_WEAVER := "res://scenes/bosses/GriefWeaver.tscn"

## Ordered 1..10 rotation used by both boss_scene_for_floor() and
## act_for_floor() so "the boss you're about to meet" and "the minions
## foreshadowing them" always line up.
const BOSS_ROTATION := [
	BOSS_MATRIARCH,   # 1: floors 5, 55, 105...
	BOSS_CHORISTER,   # 2: floors 10, 60, 110...
	BOSS_WARDEN,      # 3: floors 15, 65, 115...
	BOSS_TYRANT,      # 4: floors 20, 70, 120...
	BOSS_CANTOR,      # 5: floors 25, 75, 125...
	BOSS_INQUISITOR,  # 6: floors 30, 80, 130...
	BOSS_CHOIR,       # 7: floors 35, 85, 135...
	BOSS_KING,        # 8: floors 40, 90, 140...
	BOSS_SOVEREIGN,   # 9: floors 45, 95, 145...
	BOSS_WEAVER,      # 0 (i.e. 10th): floors 50, 100, 150...
]

## Which of the 10 Wardens "owns" this boss floor (floor must be a multiple of 5).
static func boss_scene_for_floor(floor_number: int) -> String:
	var cycle_pos: int = int(floor_number / 5) % 10
	# cycle_pos runs 1..9 then 0 (floor 50, 100...) -- map 0 to the last
	# entry in the rotation so the 10th boss lands on the "0" floors.
	var index: int = cycle_pos - 1
	if index < 0:
		index = BOSS_ROTATION.size() - 1
	return BOSS_ROTATION[index]

## Which "act" (1-10) the given floor belongs to, used to pick themed
## trash-mob pools that foreshadow the upcoming boss.
static func act_for_floor(floor_number: int) -> int:
	var cycle_pos: int = int((floor_number - 1) / 5) % 10
	return cycle_pos + 1  # 1 = leads to Matriarch, ... 10 = leads to Weaver

## Returns an Array of enemy scene paths to spawn for this floor+wave.
static func enemies_for_wave(floor_number: int, wave_number: int, total_waves: int) -> Array[String]:
	var act := act_for_floor(floor_number)
	var pool: Array[String] = [GRUNT]
	match act:
		1: pool.append_array([PIGLET, PIGLET, HOG])
		2: pool.append_array([WRAITH, LARVA, LARVA])
		3: pool.append_array([SHADE, MOTH])
		4: pool.append_array([MIRROR_WRAITH, GLARE_WISP, VAIN_DUELIST])
		5: pool.append_array([BLOAT_ROACH, SPORE_DRIFTER, HOLLOW_BEGGAR])
		6: pool.append_array([BRAND_ACOLYTE, CHAIN_WARDEN, ASHEN_ZEALOT])
		7: pool.append_array([DROWNED_HUSK, RIPTIDE_EEL, WAILING_GULL])
		8: pool.append_array([STARVED_WRETCH, CARRION_CROW, FAMINE_HUSK])
		9: pool.append_array([SPARK_WISP, THUNDER_HAWK, STATIC_DRONE])
		10: pool.append_array([BROODLING, WEEPING_SHADE, SILK_STALKER])

	var count: int = 2 + wave_number + int(floor_number / 8)
	count = clampi(count, 2, 9)

	var out: Array[String] = []
	for i in range(count):
		out.append(pool[randi() % pool.size()])
	return out
