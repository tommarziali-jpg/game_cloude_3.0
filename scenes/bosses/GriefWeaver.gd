extends BossBase
class_name GriefWeaver
## Boss #10 -- Floors 50, 100, 150...
## VISUAL MAPPING
## - Body: spider/weaver silhouette built around a web theme.
## - Web Snare: three ground anchors mark the silk trap locations.
## - Venom Spit: green burst of three aimed projectiles identifies the spit.
## - Mourning Wail: the growing sorrow ring marks the area-of-effect attack.
## - Spawn Broodlings: broodlings and weeping shades visibly answer the call.

## Boss #10 -- Floors 50, 100, 150... Grief/web theme. The memory of every
## mourner who never stopped grieving, compressed into a patient, weaving
## thing that would rather trap you than fight you. Grants an Arcana slot,
## an Artifact, and Star Shards on death.

const BROODLING_SCENE := "res://scenes/enemies/Broodling.tscn"
const WEEPING_SHADE_SCENE := "res://scenes/enemies/WeepingShade.tscn"
const SILK_STALKER_SCENE := "res://scenes/enemies/SilkStalker.tscn"

var enraged_venom: bool = false

func _ready() -> void:
	boss_display_name = "The Grief Weaver"
	max_health = 290.0
	move_speed = 75.0
	attack_pattern = ["web_snare", "venom_spit", "mourning_wail", "spawn_broodlings", "web_snare"]
	super._ready()

# --------------------------------------------------------------- ATTACK 1
## Throws three web anchors that root and damage the player if they linger
## near them -- Binding Chains, reskinned as silk.
func web_snare() -> void:
	set_next_attack_delay(2.9)
	var anchors: Array = []
	for i in range(3):
		var angle := randf_range(0, TAU)
		var r := randf_range(40, arena_radius * 0.8)
		anchors.append(arena_center + Vector2(cos(angle), sin(angle)) * r)
	_watch_web(anchors)

func _watch_web(anchors: Array) -> void:
	var t := 0.0
	var duration := 2.0
	while t < duration and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		for a in anchors:
			if player_pos().distance_to(a) < 40.0:
				if player_ref and player_ref.has_method("take_damage"):
					player_ref.take_damage(4.0 * difficulty_scale * get_physics_process_delta_time(), self)
				if player_ref and player_ref.has_method("drain_dash"):
					player_ref.drain_dash(0.3)
		await get_tree().physics_frame

# --------------------------------------------------------------- ATTACK 2
## A tight, fast burst of venom projectiles -- fewer and quicker than the
## Matriarch's Cinder Storm, aimed rather than a full ring.
func venom_spit() -> void:
	set_next_attack_delay(2.4)
	is_busy = true
	if visual:
		visual.modulate = Color(1.3, 1.6, 0.9)
	await get_tree().create_timer(0.35).timeout
	if visual:
		visual.modulate = Color(1, 1, 1)
	if is_dead or not is_instance_valid(self):
		is_busy = false
		return
	var base_dir: Vector2 = (player_pos() - global_position).normalized()
	for i in range(3):
		var spread: float = deg_to_rad(-10 + i * 10)
		var dir := base_dir.rotated(spread)
		fire_projectile(dir, 6.0 * difficulty_scale, 300.0)
	is_busy = false

# --------------------------------------------------------------- ATTACK 3
## A growing ring of sorrow that deals more damage the longer the player
## stays inside it -- Discordant Wail, reskinned.
func mourning_wail() -> void:
	set_next_attack_delay(3.0)
	var t := 0.0
	var duration := 1.5
	while t < duration and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		var dist := player_pos().distance_to(global_position)
		if dist < 190.0:
			var ramp: float = t / duration
			if player_ref and player_ref.has_method("take_damage"):
				player_ref.take_damage(4.0 * ramp * difficulty_scale * get_physics_process_delta_time() * 4.0, self)
		await get_tree().physics_frame

# --------------------------------------------------------------- ATTACK 4
func spawn_broodlings() -> void:
	set_next_attack_delay(3.5)
	spawn_minion(BROODLING_SCENE, Vector2(50, 30))
	spawn_minion(BROODLING_SCENE, Vector2(-50, 30))
	spawn_minion(WEEPING_SHADE_SCENE, Vector2(0, -55))

func enrage() -> void:
	enraged_venom = true
	spawn_minion(SILK_STALKER_SCENE, Vector2(0, 60))
	move_speed += 10.0
