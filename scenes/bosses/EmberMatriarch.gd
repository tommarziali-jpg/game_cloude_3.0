extends BossBase
class_name EmberMatriarch
## Boss #1 -- Floors 5, 55, 105... Feral fire/tusk theme. See docs/STORY.md
## VISUAL MAPPING
## - Body: fiery boar/war-matriarch silhouette with visible tusks.
## - Charge Slam: bright windup and enlarged body show the charging hitbox.
## - Tusk Sweep: close-range flash around the tusks marks the sweep.
## - Cinder Storm: eight ember projectiles radiate in a full ring.
## - Call the Herd: summoned piglets/hog visually represent the herd call.

## Bestiary for full lore. Grants an Arcana slot, an Artifact, and Star Shards on death.
##
## Tuned to be a fair "first boss": lower HP than later bosses, every attack
## has a visible windup before it can land, and the pace between attacks is
## slow enough to read and react to.

const PIGLET_SCENE := "res://scenes/enemies/TuskedPiglet.tscn"
const HOG_SCENE := "res://scenes/enemies/EmberHog.tscn"

var enraged_speed_bonus: float = 0.0

func _ready() -> void:
	boss_display_name = "The Ember Matriarch"
	max_health = 170.0
	move_speed = 80.0
	attack_pattern = ["charge_slam", "tusk_sweep", "cinder_storm", "call_the_herd", "tusk_sweep"]
	super._ready()

func enrage() -> void:
	enraged_speed_bonus = 25.0
	move_speed += enraged_speed_bonus

# --------------------------------------------------------------- ATTACK 1
func charge_slam() -> void:
	set_next_attack_delay(3.0)
	if is_busy:
		return
	is_busy = true

	# Windup: she plants her feet and flashes before actually charging, so
	# the direction (and the fact that a charge is coming at all) is
	# telegraphed before any movement happens.
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
	var end_pos: Vector2 = global_position + dir * 420.0
	var t: float = 0.0
	var duration := 0.45
	var start_pos := global_position
	while t < duration and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		global_position = start_pos.lerp(end_pos, clamp(t / duration, 0.0, 1.0))
		if global_position.distance_to(player_pos()) < 45.0 and player_ref and player_ref.has_method("take_damage"):
			player_ref.take_damage(14.0 * difficulty_scale, self)
			if player_ref.has_method("external_pull"):
				player_ref.external_pull(global_position + dir * 60.0, 0.6)
		await get_tree().physics_frame
	is_busy = false

# --------------------------------------------------------------- ATTACK 2
func tusk_sweep() -> void:
	set_next_attack_delay(2.2)
	is_busy = true
	if visual:
		visual.modulate = Color(1.7, 1.2, 0.6)
	await get_tree().create_timer(0.35).timeout
	if visual:
		visual.modulate = Color(1, 1, 1)
	if not is_dead and is_instance_valid(self) and player_pos().distance_to(global_position) < 95.0 and player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(10.0 * difficulty_scale, self)
		if player_ref.has_method("external_pull"):
			var away: Vector2 = (player_pos() - global_position).normalized()
			player_ref.external_pull(player_pos() + away * 40.0, 0.2)
	is_busy = false

# --------------------------------------------------------------- ATTACK 3
func cinder_storm() -> void:
	set_next_attack_delay(2.8)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		fire_projectile(Vector2(cos(angle), sin(angle)), 8.0 * difficulty_scale, 240.0)

# --------------------------------------------------------------- ATTACK 4
func call_the_herd() -> void:
	set_next_attack_delay(3.4)
	spawn_minion(PIGLET_SCENE, Vector2(60, 0))
	spawn_minion(PIGLET_SCENE, Vector2(-60, 0))
	spawn_minion(HOG_SCENE, Vector2(0, 60))
