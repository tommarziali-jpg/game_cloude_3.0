extends BossBase
class_name HollowChorister

## Boss #2 -- Floors 10, 20, 30... Chains/sound theme. See docs/STORY.md
## Bestiary. Grants an Arcana slot, an Artifact, and Star Shards on death.
##
## Tuned for fairness: lower HP, a real windup on Chain Lash (previously an
## instant unavoidable hit if you were in range when it was chosen), and a
## slower pace between attacks overall.

const LARVA_SCENE := "res://scenes/enemies/EchoLarva.tscn"
const WRAITH_SCENE := "res://scenes/enemies/ChainWraith.tscn"

var untargetable: bool = false

func _ready() -> void:
	boss_display_name = "The Hollow Chorister"
	max_health = 220.0
	move_speed = 58.0
	attack_pattern = ["chain_lash", "binding_chains", "discordant_wail", "choir_of_the_bound", "chain_lash"]
	super._ready()

func take_damage(amount: float, source: Node = null, is_dot: bool = false) -> void:
	if untargetable:
		return
	super.take_damage(amount, source, is_dot)

# --------------------------------------------------------------- ATTACK 1
func chain_lash() -> void:
	set_next_attack_delay(2.4)
	is_busy = true
	# Windup: chains rattle and glow before the lash actually reaches out,
	# instead of landing the instant this attack is picked.
	if visual:
		visual.modulate = Color(1.3, 1.1, 1.6)
	await get_tree().create_timer(0.4).timeout
	if visual:
		visual.modulate = Color(1, 1, 1)
	if not is_dead and is_instance_valid(self) and player_pos().distance_to(global_position) < 140.0 and player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(10.0 * difficulty_scale, self)
		if player_ref.has_method("external_pull"):
			player_ref.external_pull(global_position, 0.15)
	is_busy = false

# --------------------------------------------------------------- ATTACK 2
func discordant_wail() -> void:
	set_next_attack_delay(3.0)
	is_busy = true
	var t := 0.0
	var duration := 1.6
	while t < duration and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		var dist := player_pos().distance_to(global_position)
		if dist < 200.0:
			var ramp: float = t / duration
			if player_ref and player_ref.has_method("take_damage"):
				player_ref.take_damage(4.5 * ramp * difficulty_scale * get_physics_process_delta_time() * 4.0, self)
			if has_enraged and player_ref and player_ref.has_method("external_pull"):
				player_ref.external_pull(global_position, 0.02)
		await get_tree().physics_frame
	is_busy = false

# --------------------------------------------------------------- ATTACK 3
func binding_chains() -> void:
	set_next_attack_delay(2.8)
	var anchors: Array = []
	for i in range(3):
		var angle := randf_range(0, TAU)
		var r := randf_range(40, arena_radius * 0.8)
		anchors.append(arena_center + Vector2(cos(angle), sin(angle)) * r)
	_chain_root_watch(anchors)

func _chain_root_watch(anchors: Array) -> void:
	var t := 0.0
	var duration := 2.0
	while t < duration and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		for a in anchors:
			if player_pos().distance_to(a) < 40.0:
				if player_ref and player_ref.has_method("take_damage"):
					player_ref.take_damage(4.0 * difficulty_scale * get_physics_process_delta_time(), self)
				if player_ref and player_ref.has_method("drain_dash"):
					player_ref.drain_dash(0.5)
		await get_tree().physics_frame

# --------------------------------------------------------------- ATTACK 4
func choir_of_the_bound() -> void:
	set_next_attack_delay(3.6)
	spawn_minion(LARVA_SCENE, Vector2(50, 30))
	spawn_minion(LARVA_SCENE, Vector2(-50, 30))
	spawn_minion(WRAITH_SCENE, Vector2(0, -50))
	_sing()

func _sing() -> void:
	untargetable = true
	if visual:
		visual.modulate = Color(1, 1, 1, 0.35)
	await get_tree().create_timer(1.2).timeout
	untargetable = false
	if visual:
		visual.modulate = Color(1, 1, 1, 1)

func enrage() -> void:
	move_speed += 12.0
