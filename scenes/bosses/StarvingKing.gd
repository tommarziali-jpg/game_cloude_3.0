extends BossBase
class_name StarvingKing

## Boss #8 -- Floors 40, 90, 140... Famine/hunger theme. The memory of a
## siege that starved a whole court, compressed into a ravenous, once-royal
## thing that gets stronger the more it feeds. Grants an Arcana slot, an
## Artifact, and Star Shards on death.

const STARVED_WRETCH_SCENE := "res://scenes/enemies/StarvedWretch.tscn"
const CARRION_CROW_SCENE := "res://scenes/enemies/CarrionCrow.tscn"
const FAMINE_HUSK_SCENE := "res://scenes/enemies/FamineHusk.tscn"

var lifesteal_bonus: float = 0.3

func _ready() -> void:
	boss_display_name = "The Starving King"
	max_health = 280.0
	move_speed = 70.0
	attack_pattern = ["ravenous_bite", "famine_wave", "gluttonous_charge", "summon_the_starved", "ravenous_bite"]
	super._ready()

# --------------------------------------------------------------- ATTACK 1
## A heavy telegraphed bite that heals the King for a portion of the
## damage it deals -- fights against the player's DPS race directly.
func ravenous_bite() -> void:
	set_next_attack_delay(2.4)
	is_busy = true
	if visual:
		visual.modulate = Color(1.6, 1.1, 0.5)
	await get_tree().create_timer(0.4).timeout
	if visual:
		visual.modulate = Color(1, 1, 1)
	if not is_dead and is_instance_valid(self) and player_pos().distance_to(global_position) < 95.0 and player_ref and player_ref.has_method("take_damage"):
		var dmg: float = 12.0 * difficulty_scale
		player_ref.take_damage(dmg, self)
		current_health = min(max_health, current_health + dmg * lifesteal_bonus)
	is_busy = false

# --------------------------------------------------------------- ATTACK 2
## A ring of hunger-pulses, same shape as Cinder Storm, radiating outward.
func famine_wave() -> void:
	set_next_attack_delay(2.9)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		fire_projectile(Vector2(cos(angle), sin(angle)), 7.0 * difficulty_scale, 220.0)

# --------------------------------------------------------------- ATTACK 3
## A straight-line charge that heals the King on a landed hit, same shape
## as Charge Slam.
func gluttonous_charge() -> void:
	set_next_attack_delay(3.0)
	if is_busy:
		return
	is_busy = true
	if visual:
		visual.modulate = Color(1.7, 1.2, 0.6)
		visual.scale = Vector2(1.2, 1.2)
	var windup_t := 0.0
	while windup_t < 0.5 and is_instance_valid(self) and not is_dead:
		windup_t += get_physics_process_delta_time()
		await get_tree().physics_frame
	if visual:
		visual.modulate = Color(1, 1, 1)
		visual.scale = Vector2(1, 1)
	if is_dead or not is_instance_valid(self):
		is_busy = false
		return
	var dir: Vector2 = (player_pos() - global_position).normalized()
	var end_pos: Vector2 = global_position + dir * 400.0
	var t: float = 0.0
	var duration := 0.45
	var start_pos := global_position
	while t < duration and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		global_position = start_pos.lerp(end_pos, clamp(t / duration, 0.0, 1.0))
		if global_position.distance_to(player_pos()) < 45.0 and player_ref and player_ref.has_method("take_damage"):
			var dmg: float = 14.0 * difficulty_scale
			player_ref.take_damage(dmg, self)
			current_health = min(max_health, current_health + dmg * lifesteal_bonus)
		await get_tree().physics_frame
	is_busy = false

# --------------------------------------------------------------- ATTACK 4
func summon_the_starved() -> void:
	set_next_attack_delay(3.4)
	spawn_minion(STARVED_WRETCH_SCENE, Vector2(55, 0))
	spawn_minion(STARVED_WRETCH_SCENE, Vector2(-55, 0))
	spawn_minion(CARRION_CROW_SCENE, Vector2(0, -55))

func enrage() -> void:
	lifesteal_bonus = 0.5
	spawn_minion(FAMINE_HUSK_SCENE, Vector2(0, 60))
