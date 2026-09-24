extends BossBase
class_name IronInquisitor
## Boss #6 -- Floors 30, 80, 130...
## VISUAL MAPPING
## - Body: heavy armored tribunal/warden silhouette.
## - Branding Iron: enlarged glowing body is the clear heavy-strike windup.
## - Verdict Slam: close-range impact cue represents the iron gavel.
## - Chain Gauntlet: three visible chain anchor areas show where the chains hold.
## - Summon Tribunal: three themed acolyte/warden/zealot summons are the visual cue.

## Boss #6 -- Floors 30, 80, 130... Judgment/branding-iron theme. The
## memory of every tribunal that condemned an innocent to make an example
## of them, compressed into an armored thing that still believes it is
## righteous. Grants an Arcana slot, an Artifact, and Star Shards on death.

const BRAND_ACOLYTE_SCENE := "res://scenes/enemies/BrandAcolyte.tscn"
const CHAIN_WARDEN_SCENE := "res://scenes/enemies/ChainWarden.tscn"
const ASHEN_ZEALOT_SCENE := "res://scenes/enemies/AshenZealot.tscn"

var armored: bool = false

func _ready() -> void:
	boss_display_name = "The Iron Inquisitor"
	max_health = 300.0
	move_speed = 65.0
	attack_pattern = ["branding_iron", "verdict_slam", "chain_gauntlet", "summon_tribunal", "branding_iron"]
	super._ready()

func take_damage(amount: float, source: Node = null, is_dot: bool = false) -> void:
	var final_amount: float = amount * 0.6 if armored else amount
	super.take_damage(final_amount, source, is_dot)

# --------------------------------------------------------------- ATTACK 1
## A slow, heavy, unmissable telegraphed strike -- the "you had this
## coming" hit. Long windup, high damage, easy to dodge if you're paying
## attention.
func branding_iron() -> void:
	set_next_attack_delay(2.6)
	is_busy = true
	if visual:
		visual.modulate = Color(1.8, 1.2, 0.5)
		visual.scale = Vector2(1.15, 1.15)
	await get_tree().create_timer(0.55).timeout
	if visual:
		visual.modulate = Color(1, 1, 1)
		visual.scale = Vector2(1, 1)
	if not is_dead and is_instance_valid(self) and player_pos().distance_to(global_position) < 90.0 and player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(17.0 * difficulty_scale, self)
	is_busy = false

# --------------------------------------------------------------- ATTACK 2
## A ground-slam pulse around the Inquisitor -- bigger radius than the
## Matriarch's Tusk Sweep, representing an iron gavel striking the floor.
func verdict_slam() -> void:
	set_next_attack_delay(3.0)
	is_busy = true
	if visual:
		visual.modulate = Color(1.6, 1.3, 0.6)
	await get_tree().create_timer(0.5).timeout
	if visual:
		visual.modulate = Color(1, 1, 1)
	if not is_dead and is_instance_valid(self) and player_pos().distance_to(global_position) < 130.0 and player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(12.0 * difficulty_scale, self)
		if player_ref.has_method("external_pull"):
			var away: Vector2 = (player_pos() - global_position).normalized()
			player_ref.external_pull(player_pos() + away * 50.0, 0.25)
	is_busy = false

# --------------------------------------------------------------- ATTACK 3
## Throws three judgment-chains that root and drain anyone who stays near
## them -- Binding Chains, reskinned.
func chain_gauntlet() -> void:
	set_next_attack_delay(2.9)
	var anchors: Array = []
	for i in range(3):
		var angle := randf_range(0, TAU)
		var r := randf_range(40, arena_radius * 0.8)
		anchors.append(arena_center + Vector2(cos(angle), sin(angle)) * r)
	_watch_chains(anchors)

func _watch_chains(anchors: Array) -> void:
	var t := 0.0
	var duration := 2.0
	while t < duration and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		for a in anchors:
			if player_pos().distance_to(a) < 40.0:
				if player_ref and player_ref.has_method("take_damage"):
					player_ref.take_damage(4.5 * difficulty_scale * get_physics_process_delta_time(), self)
		await get_tree().physics_frame

# --------------------------------------------------------------- ATTACK 4
func summon_tribunal() -> void:
	set_next_attack_delay(3.6)
	spawn_minion(BRAND_ACOLYTE_SCENE, Vector2(60, -20))
	spawn_minion(CHAIN_WARDEN_SCENE, Vector2(-60, -20))
	spawn_minion(ASHEN_ZEALOT_SCENE, Vector2(0, 60))

func enrage() -> void:
	armored = true
	move_speed += 6.0
