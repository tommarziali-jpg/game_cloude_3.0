extends Node

## Single source of truth for run/floor/wave state and Hub <-> Tower scene flow.

signal run_started
signal run_ended(floor_reached: int)
signal floor_started(floor_number: int, is_boss_floor: bool)
signal floor_cleared(floor_number: int)
signal wave_started(wave_number: int, total_waves: int)

const TOWER_SCENE := "res://scenes/tower/Tower.tscn"
const HUB_SCENE := "res://scenes/hub/Hub.tscn"

var current_floor: int = 1
var current_wave: int = 0
var run_active: bool = false
var prestige: int = 0  ## increases global enemy scaling slightly each full clear-cycle, optional NG+ hook

func is_boss_floor(floor_number: int = -1) -> bool:
	var f := floor_number if floor_number != -1 else current_floor
	return f % 5 == 0

## Global stat multiplier applied to enemies for the given floor. Tuned so early
## floors are gentle and difficulty ramps up steadily forever (infinite descent).
## Also folds in any Corrupted Arcana that make enemies tougher in exchange
## for more Star Shards.
func floor_difficulty_multiplier(floor_number: int = -1) -> float:
	var f := floor_number if floor_number != -1 else current_floor
	var base: float = 1.0 + float(f - 1) * 0.12 + float(prestige) * 0.5
	base *= PlayerStats.enemy_hp_multiplier()
	return base

func waves_for_floor(floor_number: int) -> int:
	if is_boss_floor(floor_number):
		return 1
	# 2-5 waves, mildly increasing with depth
	return clampi(2 + int(floor_number / 5), 2, 5)

func start_new_run() -> void:
	current_floor = 1
	current_wave = 0
	run_active = true
	PlayerStats.reset_for_new_run()
	run_started.emit()
	get_tree().change_scene_to_file(TOWER_SCENE)

func go_to_hub() -> void:
	run_active = false
	get_tree().change_scene_to_file(HUB_SCENE)

func on_floor_entered() -> void:
	floor_started.emit(current_floor, is_boss_floor())

func on_wave_started(wave_number: int) -> void:
	current_wave = wave_number
	wave_started.emit(wave_number, waves_for_floor(current_floor))

func on_floor_cleared() -> void:
	floor_cleared.emit(current_floor)

func advance_to_next_floor() -> void:
	current_floor += 1
	current_wave = 0
	if current_floor % 25 == 1 and current_floor > 1:
		prestige += 1

func on_player_died() -> void:
	if not run_active:
		return
	run_active = false
	var reached := current_floor
	PlayerStats.on_run_ended(reached)
	run_ended.emit(reached)
	call_deferred("go_to_hub")

## Called from the Hub's Tower Entrance interactable.
func enter_tower() -> void:
	start_new_run()

## Called by BossBase._die() for every boss kill. Grants an extra Arcana
## slot, a guaranteed weighted-random Artifact, and updates meta-progression
## unlock tracking (see PlayerStats._check_meta_unlocks()).
func on_boss_defeated(_boss: Node) -> void:
	PlayerStats.on_boss_defeated()
	var artifact := ArtifactDatabase.random_weighted()
	if artifact != null:
		PlayerStats.add_artifact(artifact)
