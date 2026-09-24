extends BossBase
class_name PlagueCantor
## Boss #5 -- Floors 25, 75, 125...
## VISUAL MAPPING
## - Body: hunched plague-singer silhouette with sickly coloring.
## - Wretched Cough: greenish flash and forward cone identify the sickness attack.
## - Bone Rain: six slow projectiles form the visible bone-shard ring.
## - Festering Swarm: roaches and spore drifters visibly arrive as the swarm.
## - Quarantine Zone: marked ground circles show the temporary toxic zones.

## Boss #5 -- Floors 25, 75, 125... Rot/disease theme. The memory of every
## plague that ever swept a village too poor to flee it, compressed into a
## slow, patient, singing thing. Grants an Arcana slot, an Artifact, and
## Star Shards on death.

const BLOAT_ROACH_SCENE := "res://scenes/enemies/BloatRoach.tscn"
const SPORE_DRIFTER_SCENE := "res://scenes/enemies/SporeDrifter.tscn"
const HOLLOW_BEGGAR_SCENE := "res://scenes/enemies/HollowBeggar.tscn"

var wail_range_bonus: float = 0.0

func _ready() -> void:
	boss_display_name = "The Plague Cantor"
	max_health = 240.0
	move_speed = 60.0
	attack_pattern = ["wretched_cough", "bone_rain", "festering_swarm", "quarantine_zone", "wretched_cough"]
	super._ready()

# --------------------------------------------------------------- ATTACK 1
## A widening cone of sickness in front of the Cantor -- ramping damage the
## longer the player stays inside it, same shape as Discordant Wail but a
## cone instead of a ring so it can actually be sidestepped.
func wretched_cough() -> void:
	set_next_attack_delay(2.6)
	is_busy = true
	if visual:
		visual.modulate = Color(1.3, 1.5, 0.8)
	await get_tree().create_timer(0.4).timeout
	if visual:
		visual.modulate = Color(1, 1, 1)
	var t := 0.0
	var duration := 1.2
	var facing: Vector2 = (player_pos() - global_position).normalized() if global_position != player_pos() else Vector2.DOWN
	while t < duration and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		var to_player: Vector2 = player_pos() - global_position
		var dist := to_player.length()
		var in_cone: bool = dist < (220.0 + wail_range_bonus) and abs(facing.angle_to(to_player.normalized())) < 0.6
		if in_cone and player_ref and player_ref.has_method("take_damage"):
			var ramp: float = t / duration
			player_ref.take_damage(4.0 * ramp * difficulty_scale * get_physics_process_delta_time() * 4.0, self)
		await get_tree().physics_frame
	is_busy = false

# --------------------------------------------------------------- ATTACK 2
## A slower ring of projectiles representing infected bone-shards raining
## down -- the Ember Matriarch's Cinder Storm shape, fewer and slower.
func bone_rain() -> void:
	set_next_attack_delay(3.0)
	for i in range(6):
		var angle := TAU * float(i) / 6.0
		fire_projectile(Vector2(cos(angle), sin(angle)), 7.0 * difficulty_scale, 160.0)

# --------------------------------------------------------------- ATTACK 3
func festering_swarm() -> void:
	set_next_attack_delay(3.6)
	spawn_minion(BLOAT_ROACH_SCENE, Vector2(55, 20))
	spawn_minion(BLOAT_ROACH_SCENE, Vector2(-55, 20))
	spawn_minion(SPORE_DRIFTER_SCENE, Vector2(0, -55))

# --------------------------------------------------------------- ATTACK 4
## Marks three ground zones that deal damage over time to anyone standing
## in them -- a stationary hazard version of Binding Chains, representing
## the ground itself going toxic.
func quarantine_zone() -> void:
	set_next_attack_delay(3.2)
	var zones: Array = []
	for i in range(3):
		var angle := randf_range(0, TAU)
		var r := randf_range(40, arena_radius * 0.75)
		zones.append(arena_center + Vector2(cos(angle), sin(angle)) * r)
	_watch_zones(zones)

func _watch_zones(zones: Array) -> void:
	var t := 0.0
	var duration := 2.2
	while t < duration and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		for z in zones:
			if player_pos().distance_to(z) < 50.0:
				if player_ref and player_ref.has_method("take_damage"):
					player_ref.take_damage(3.5 * difficulty_scale * get_physics_process_delta_time(), self)
		await get_tree().physics_frame

func enrage() -> void:
	wail_range_bonus = 60.0
	spawn_minion(HOLLOW_BEGGAR_SCENE, Vector2(0, 60))
