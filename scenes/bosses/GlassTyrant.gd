extends BossBase
class_name GlassTyrant

## Boss #4 -- Floors 20, 70, 120... Mirrors/reflection theme. The memory of
## every soldier who broke and hid behind someone else's body, compressed
## into a vain, cruel thing that loves nothing but its own reflection.
## Grants an Arcana slot, an Artifact, and Star Shards on death.

const MIRROR_WRAITH_SCENE := "res://scenes/enemies/MirrorWraith.tscn"
const GLARE_WISP_SCENE := "res://scenes/enemies/GlareWisp.tscn"
const VAIN_DUELIST_SCENE := "res://scenes/enemies/VainDuelist.tscn"

var untargetable: bool = false

func _ready() -> void:
	boss_display_name = "The Glass Tyrant"
	max_health = 260.0
	move_speed = 85.0
	attack_pattern = ["mirror_lunge", "shatterframe_wave", "hall_of_mirrors", "grasping_reflections", "mirror_lunge"]
	super._ready()

func take_damage(amount: float, source: Node = null, is_dot: bool = false) -> void:
	if untargetable:
		return
	super.take_damage(amount, source, is_dot)

# --------------------------------------------------------------- ATTACK 1
## Blinks behind the player and strikes -- telegraphed by the boss fading
## into a mirror-sheen before it reappears.
func mirror_lunge() -> void:
	set_next_attack_delay(2.6)
	is_busy = true
	if visual:
		visual.modulate = Color(1.6, 1.6, 2.0, 0.45)
	await get_tree().create_timer(0.45).timeout
	if is_dead or not is_instance_valid(self):
		is_busy = false
		return
	if visual:
		visual.modulate = Color(1, 1, 1, 1)
	var target: Vector2 = player_pos()
	var back_off: Vector2 = (global_position - target).normalized() if global_position != target else Vector2.DOWN
	global_position = target - back_off * 55.0
	if global_position.distance_to(player_pos()) < 70.0 and player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(13.0 * difficulty_scale, self)
	is_busy = false

# --------------------------------------------------------------- ATTACK 2
## A ring of shard-shrapnel fired outward, straight from Ember Matriarch's
## Cinder Storm but reskinned as broken glass.
func shatterframe_wave() -> void:
	set_next_attack_delay(2.8)
	for i in range(10):
		var angle := TAU * float(i) / 10.0
		fire_projectile(Vector2(cos(angle), sin(angle)), 7.0 * difficulty_scale, 260.0)

# --------------------------------------------------------------- ATTACK 3
## Spawns two illusory Mirror Wraiths and becomes briefly untargetable --
## the real Tyrant is hiding among its own reflections.
func hall_of_mirrors() -> void:
	set_next_attack_delay(3.6)
	spawn_minion(MIRROR_WRAITH_SCENE, Vector2(55, 30))
	spawn_minion(MIRROR_WRAITH_SCENE, Vector2(-55, 30))
	_hide_in_reflections()

func _hide_in_reflections() -> void:
	untargetable = true
	if visual:
		visual.modulate = Color(1, 1, 1, 0.3)
	await get_tree().create_timer(1.1).timeout
	untargetable = false
	if visual:
		visual.modulate = Color(1, 1, 1, 1)

# --------------------------------------------------------------- ATTACK 4
## Throws three anchor-shards that snap a grasping reflection toward
## anyone who lingers near them, rooting and damaging -- Binding Chains
## reskinned as broken glass reaching out of a mirror.
func grasping_reflections() -> void:
	set_next_attack_delay(3.0)
	var anchors: Array = []
	for i in range(3):
		var angle := randf_range(0, TAU)
		var r := randf_range(40, arena_radius * 0.8)
		anchors.append(arena_center + Vector2(cos(angle), sin(angle)) * r)
	_watch_reflections(anchors)

func _watch_reflections(anchors: Array) -> void:
	var t := 0.0
	var duration := 2.0
	while t < duration and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		for a in anchors:
			if player_pos().distance_to(a) < 38.0:
				if player_ref and player_ref.has_method("take_damage"):
					player_ref.take_damage(4.0 * difficulty_scale * get_physics_process_delta_time(), self)
				if player_ref and player_ref.has_method("drain_dash"):
					player_ref.drain_dash(0.4)
		await get_tree().physics_frame

func enrage() -> void:
	spawn_minion(VAIN_DUELIST_SCENE, Vector2(0, -60))
	move_speed += 10.0
