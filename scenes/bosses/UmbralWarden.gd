extends BossBase
class_name UmbralWarden

## Boss #3 -- Floors 20, 40, 60... Shadow/identity theme, final tower-guardian
## tier. See docs/STORY.md Bestiary. Grants an Arcana slot, an Artifact, and Star Shards on death.
##
## Tuned for fairness: lower HP, a real windup before Duskfang Flurry's first
## hit (previously instant), and a slower pace between attacks overall.

const SHADE_SCENE := "res://scenes/enemies/ShadeClone.tscn"

func _ready() -> void:
	boss_display_name = "The Umbral Warden"
	max_health = 250.0
	move_speed = 90.0
	attack_pattern = ["umbral_blink_strike", "duskfang_flurry", "shattered_mirror", "voidwake", "duskfang_flurry"]
	super._ready()

func enrage() -> void:
	move_speed += 18.0

# --------------------------------------------------------------- ATTACK 1
func umbral_blink_strike() -> void:
	set_next_attack_delay(2.6)
	await _do_blink_strike()
	if has_enraged:
		await get_tree().create_timer(0.45).timeout
		await _do_blink_strike()

func _do_blink_strike() -> void:
	if not is_instance_valid(self) or is_dead:
		return
	var target: Vector2 = player_pos()
	var behind_dir: Vector2 = Vector2.DOWN
	if player_ref and player_ref.get("facing") != null:
		behind_dir = player_ref.get("facing")
	var strike_pos: Vector2 = target - behind_dir * 55.0
	if visual:
		visual.modulate = Color(0.4, 0.2, 0.6, 0.4)
	await get_tree().create_timer(0.45).timeout
	if not is_instance_valid(self) or is_dead:
		return
	if visual:
		visual.modulate = Color(1, 1, 1, 1)
	global_position = strike_pos
	if global_position.distance_to(player_pos()) < 70.0 and player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(15.0 * difficulty_scale, self)

# --------------------------------------------------------------- ATTACK 2
func duskfang_flurry() -> void:
	set_next_attack_delay(2.6)
	is_busy = true
	# Windup before the FIRST hit -- previously this attack could land the
	# instant it was chosen if the player happened to already be close.
	if visual:
		visual.modulate = Color(1.5, 1.1, 1.6)
	await get_tree().create_timer(0.3).timeout
	if visual:
		visual.modulate = Color(1, 1, 1)
	for i in range(4):
		if not is_instance_valid(self) or is_dead:
			break
		if global_position.distance_to(player_pos()) < 90.0 and player_ref and player_ref.has_method("take_damage"):
			player_ref.take_damage(5.0 * difficulty_scale, self)
		await get_tree().create_timer(0.2).timeout
	is_busy = false

# --------------------------------------------------------------- ATTACK 3
func shattered_mirror() -> void:
	set_next_attack_delay(3.4)
	spawn_minion(SHADE_SCENE, Vector2(70, 40))
	spawn_minion(SHADE_SCENE, Vector2(-70, 40))

# --------------------------------------------------------------- ATTACK 4
func voidwake() -> void:
	set_next_attack_delay(3.0)
	is_busy = true
	var t := 0.0
	var duration := 1.4
	var start_angle := randf_range(0, TAU)
	while t < duration and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		var angle: float = start_angle + (t / duration) * TAU
		global_position = arena_center + Vector2(cos(angle), sin(angle)) * (arena_radius * 0.75)
		if global_position.distance_to(player_pos()) < 55.0 and player_ref and player_ref.has_method("take_damage"):
			player_ref.take_damage(3.0 * difficulty_scale * get_physics_process_delta_time() * 4.0, self)
		await get_tree().physics_frame
	is_busy = false
