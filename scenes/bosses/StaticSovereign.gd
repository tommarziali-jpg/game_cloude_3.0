extends BossBase
class_name StaticSovereign

## Boss #9 -- Floors 45, 95, 145... Storm/lightning theme. The memory of
## every storm that ever drowned out a scream, compressed into something
## fast, erratic, and impossible to fully predict. Grants an Arcana slot,
## an Artifact, and Star Shards on death.

const SPARK_WISP_SCENE := "res://scenes/enemies/SparkWisp.tscn"
const THUNDER_HAWK_SCENE := "res://scenes/enemies/ThunderHawk.tscn"
const STATIC_DRONE_SCENE := "res://scenes/enemies/StaticDrone.tscn"

func _ready() -> void:
	boss_display_name = "The Static Sovereign"
	max_health = 270.0
	move_speed = 110.0
	attack_pattern = ["chain_lightning", "storm_dash", "thunderclap", "call_the_tempest", "storm_dash"]
	super._ready()

# --------------------------------------------------------------- ATTACK 1
## A fast triple-shot burst fired in a narrow spread toward the player --
## short telegraph, high speed, rewards keeping some lateral distance.
func chain_lightning() -> void:
	set_next_attack_delay(2.2)
	is_busy = true
	if visual:
		visual.modulate = Color(1.6, 1.6, 0.7)
	await get_tree().create_timer(0.3).timeout
	if visual:
		visual.modulate = Color(1, 1, 1)
	if is_dead or not is_instance_valid(self):
		is_busy = false
		return
	var base_dir: Vector2 = (player_pos() - global_position).normalized()
	for i in range(3):
		var spread: float = deg_to_rad(-12 + i * 12)
		fire_projectile(base_dir.rotated(spread), 6.0 * difficulty_scale, 420.0)
	is_busy = false

# --------------------------------------------------------------- ATTACK 2
## Two rapid teleport-strikes in a row -- a faster, twitchier cousin of the
## Umbral Warden's Blink Strike, themed as jumping along a lightning arc.
func storm_dash() -> void:
	set_next_attack_delay(2.4)
	await _do_storm_strike()
	await get_tree().create_timer(0.25).timeout
	if not is_dead and is_instance_valid(self):
		await _do_storm_strike()

func _do_storm_strike() -> void:
	if not is_instance_valid(self) or is_dead:
		return
	var target: Vector2 = player_pos()
	if visual:
		visual.modulate = Color(1.4, 1.4, 0.5, 0.4)
	await get_tree().create_timer(0.28).timeout
	if not is_instance_valid(self) or is_dead:
		return
	if visual:
		visual.modulate = Color(1, 1, 1, 1)
	var offset := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 50.0
	global_position = target + offset
	if global_position.distance_to(player_pos()) < 65.0 and player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(9.0 * difficulty_scale, self)

# --------------------------------------------------------------- ATTACK 3
## An instant AoE pulse around the Sovereign -- short range, no windup
## beyond a flash, punishes staying in melee range on cooldown.
func thunderclap() -> void:
	set_next_attack_delay(2.8)
	if visual:
		visual.modulate = Color(1.7, 1.7, 0.9)
		var tween := create_tween()
		tween.tween_property(visual, "modulate", Color(1, 1, 1), 0.2)
	if player_pos().distance_to(global_position) < 110.0 and player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(9.0 * difficulty_scale, self)

# --------------------------------------------------------------- ATTACK 4
func call_the_tempest() -> void:
	set_next_attack_delay(3.4)
	spawn_minion(SPARK_WISP_SCENE, Vector2(55, -30))
	spawn_minion(SPARK_WISP_SCENE, Vector2(-55, -30))
	spawn_minion(THUNDER_HAWK_SCENE, Vector2(0, 55))

func enrage() -> void:
	move_speed += 30.0
	spawn_minion(STATIC_DRONE_SCENE, Vector2(0, 0))
