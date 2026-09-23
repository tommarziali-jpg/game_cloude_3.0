extends BossBase
class_name DrownedChoir

## Boss #7 -- Floors 35, 85, 135... Drowning/current theme. The memory of
## every sailor and villager the Spire's floodwater-floors ever pulled
## under, compressed into a slow, relentless undertow. Grants an Arcana
## slot, an Artifact, and Star Shards on death.

const DROWNED_HUSK_SCENE := "res://scenes/enemies/DrownedHusk.tscn"
const RIPTIDE_EEL_SCENE := "res://scenes/enemies/RiptideEel.tscn"
const WAILING_GULL_SCENE := "res://scenes/enemies/WailingGull.tscn"

var enraged_pull: bool = false

func _ready() -> void:
	boss_display_name = "The Drowned Choir"
	max_health = 260.0
	move_speed = 60.0
	attack_pattern = ["riptide_pull", "tidal_surge", "whirlpool", "call_the_drowned", "tidal_surge"]
	super._ready()

# --------------------------------------------------------------- ATTACK 1
## Channels an undertow that steadily drags the player toward the Choir --
## survivable alone, but dangerous if it lines the player up for the next
## attack. A channelled pull rather than a single yank, so it can be
## fought against by moving away the whole time.
func riptide_pull() -> void:
	set_next_attack_delay(2.8)
	var t := 0.0
	var duration := 1.6
	while t < duration and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		if player_ref and player_ref.has_method("external_pull"):
			player_ref.external_pull(global_position, 0.04)
		if player_pos().distance_to(global_position) < 70.0 and player_ref and player_ref.has_method("take_damage"):
			player_ref.take_damage(3.0 * difficulty_scale * get_physics_process_delta_time(), self)
		await get_tree().physics_frame

# --------------------------------------------------------------- ATTACK 2
## A straight-line charge, identical in shape to Charge Slam but themed as
## a wave crashing across the arena.
func tidal_surge() -> void:
	set_next_attack_delay(3.0)
	if is_busy:
		return
	is_busy = true
	if visual:
		visual.modulate = Color(0.6, 1.2, 1.6)
	var windup_t := 0.0
	while windup_t < 0.5 and is_instance_valid(self) and not is_dead:
		windup_t += get_physics_process_delta_time()
		await get_tree().physics_frame
	if visual:
		visual.modulate = Color(1, 1, 1)
	if is_dead or not is_instance_valid(self):
		is_busy = false
		return
	var dir: Vector2 = (player_pos() - global_position).normalized()
	var end_pos: Vector2 = global_position + dir * 380.0
	var t: float = 0.0
	var duration := 0.5
	var start_pos := global_position
	while t < duration and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		global_position = start_pos.lerp(end_pos, clamp(t / duration, 0.0, 1.0))
		if global_position.distance_to(player_pos()) < 48.0 and player_ref and player_ref.has_method("take_damage"):
			player_ref.take_damage(13.0 * difficulty_scale, self)
			if player_ref.has_method("external_pull"):
				player_ref.external_pull(global_position + dir * 60.0, 0.5)
		await get_tree().physics_frame
	is_busy = false

# --------------------------------------------------------------- ATTACK 3
## Spawns a slow-growing whirlpool hazard at a random point that the
## player must stay clear of, growing over its lifetime.
func whirlpool() -> void:
	set_next_attack_delay(3.4)
	var angle := randf_range(0, TAU)
	var r := randf_range(30, arena_radius * 0.7)
	var center: Vector2 = arena_center + Vector2(cos(angle), sin(angle)) * r
	_watch_whirlpool(center)

func _watch_whirlpool(center: Vector2) -> void:
	var t := 0.0
	var duration := 2.4
	while t < duration and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		var radius: float = lerp(20.0, 90.0, t / duration)
		if player_pos().distance_to(center) < radius:
			if player_ref and player_ref.has_method("take_damage"):
				player_ref.take_damage(4.0 * difficulty_scale * get_physics_process_delta_time(), self)
			if enraged_pull and player_ref and player_ref.has_method("external_pull"):
				player_ref.external_pull(center, 0.03)
		await get_tree().physics_frame

# --------------------------------------------------------------- ATTACK 4
func call_the_drowned() -> void:
	set_next_attack_delay(3.6)
	spawn_minion(DROWNED_HUSK_SCENE, Vector2(55, 30))
	spawn_minion(RIPTIDE_EEL_SCENE, Vector2(-55, 30))
	spawn_minion(WAILING_GULL_SCENE, Vector2(0, -55))

func enrage() -> void:
	enraged_pull = true
	move_speed += 10.0
