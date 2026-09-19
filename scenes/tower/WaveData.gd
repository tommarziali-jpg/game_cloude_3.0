extends Node
class_name WaveData

## Pure-data helper: decides which enemies spawn on a given floor/wave, and
## which boss owns a given boss floor. A boss appears every 5th floor,
## rotating Ember Matriarch -> Hollow Chorister -> Umbral Warden forever, so
## each boss's own minions (see docs/STORY.md) show up in the regular waves
## on the floors leading up to "their" boss floor.

const GRUNT := "res://scenes/enemies/Grunt.tscn"
const PIGLET := "res://scenes/enemies/TuskedPiglet.tscn"
const HOG := "res://scenes/enemies/EmberHog.tscn"
const WRAITH := "res://scenes/enemies/ChainWraith.tscn"
const LARVA := "res://scenes/enemies/EchoLarva.tscn"
const SHADE := "res://scenes/enemies/ShadeClone.tscn"
const MOTH := "res://scenes/enemies/VoidMoth.tscn"

const BOSS_MATRIARCH := "res://scenes/bosses/EmberMatriarch.tscn"
const BOSS_CHORISTER := "res://scenes/bosses/HollowChorister.tscn"
const BOSS_WARDEN := "res://scenes/bosses/UmbralWarden.tscn"

## Which of the 3 bosses "owns" this boss floor (floor must be a multiple of 5).
static func boss_scene_for_floor(floor_number: int) -> String:
	var cycle_pos: int = int(floor_number / 5) % 3
	match cycle_pos:
		1: return BOSS_MATRIARCH   # floors 5, 20, 35...
		2: return BOSS_CHORISTER   # floors 10, 25, 40...
		0: return BOSS_WARDEN      # floors 15, 30, 45...
	return BOSS_MATRIARCH

## Which "act" (1, 2, or 3) the given floor belongs to, used to pick themed
## trash-mob pools that foreshadow the upcoming boss.
static func act_for_floor(floor_number: int) -> int:
	var cycle_pos: int = int((floor_number - 1) / 5) % 3
	return cycle_pos + 1  # 1 = leads to Matriarch, 2 = leads to Chorister, 3 = leads to Warden

## Returns an Array of enemy scene paths to spawn for this floor+wave.
static func enemies_for_wave(floor_number: int, wave_number: int, total_waves: int) -> Array[String]:
	var act := act_for_floor(floor_number)
	var pool: Array[String] = [GRUNT]
	match act:
		1: pool.append_array([PIGLET, PIGLET, HOG])
		2: pool.append_array([WRAITH, LARVA, LARVA])
		3: pool.append_array([SHADE, MOTH])

	var count: int = 2 + wave_number + int(floor_number / 8)
	count = clampi(count, 2, 9)

	var out: Array[String] = []
	for i in range(count):
		out.append(pool[randi() % pool.size()])
	return out
