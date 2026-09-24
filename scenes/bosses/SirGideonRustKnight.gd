extends BossBase
class_name SirGideonRustKnight

## Sir Gideon, The Rust Knight -- Weight and Decay.
## A towering iron warrior whose mace cracks the tower floor.
##
## The old Drowned Choir attack set is intentionally gone. Gideon uses five
## attacks in a fixed round-robin pattern, with permanent arena fissures and
## a rust defense debuff as the fight progresses.

const RUST_CLOUD_RADIUS := 125.0
const FISSURE_WIDTH := 30.0
const MAX_FISSURES := 3

var enraged: bool = false
var damage_multiplier: float = 1.0
var incoming_damage_multiplier: float = 1.0
var fissure_count: int = 0

func _ready() -> void:
	boss_display_name = "Sir Gideon, The Rust Knight"
	max_health = 340.0
	move_speed = 52.0
	attack_pattern = [
		"anvil_drop",
		"rust_cloud",
		"iron_chain_drag",
		"magnetic_pull",
		"fissure_strike",
	]
	super._ready()

func take_damage(amount: float, source: Node = null, is_dot: bool = false) -> void:
	super.take_damage(amount * incoming_damage_multiplier, source, is_dot)

# --------------------------------------------------------------- ATTACK 1
## Anvil Drop: Gideon appears to leap high, relocates to the telegraphed
## landing point, and sends a large shockwave across the floor. The player
## can dash through the wave while the dash i-frames are active.
func anvil_drop() -> void:
	set_next_attack_delay(3.4)
	is_busy = true
	var landing_point := player_pos()
	if visual:
		visual.modulate = Color(1.35, 0.9, 0.55, 1.0)
		visual.scale = Vector2(1.3, 1.3)

	await get_tree().create_timer(0.7).timeout
	if is_dead or not is_instance_valid(self):
		is_busy = false
		return

	global_position = landing_point
	if visual:
		visual.modulate = Color(1, 1, 1, 1)
		visual.scale = Vector2(1, 1)

	_spawn_shockwave(global_position, 235.0, 0.7, 18.0 * damage_multiplier)
	is_busy = false

# --------------------------------------------------------------- ATTACK 2
## Rust Cloud: a lingering orange cloud that lowers the player's effective
## defense while they remain inside it.
func rust_cloud() -> void:
	set_next_attack_delay(3.5)
	var cloud := Polygon2D.new()
	var points := PackedVector2Array()
	for i in range(33):
		var a := TAU * float(i) / 32.0
		points.append(Vector2(cos(a), sin(a)) * RUST_CLOUD_RADIUS)
	cloud.polygon = points
	cloud.color = Color(0.82, 0.31, 0.08, 0.24)
	cloud.global_position = global_position
	cloud.z_index = 1
	get_tree().current_scene.add_child(cloud)

	var t := 0.0
	var rust_tick := 0.0
	var duration := 3.0
	while t < duration and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		rust_tick -= get_physics_process_delta_time()
		var pulse := 1.0 + sin(t * 8.0) * 0.04
		cloud.scale = Vector2.ONE * pulse
		if rust_tick <= 0.0 and player_ref and is_instance_valid(player_ref):
			if player_pos().distance_to(cloud.global_position) <= RUST_CLOUD_RADIUS:
				if player_ref.has_method("apply_rust_defense_reduction"):
					player_ref.apply_rust_defense_reduction(0.25, 4.0)
				rust_tick = 0.75
		await get_tree().physics_frame

	if is_instance_valid(cloud):
		var fade := create_tween()
		fade.tween_property(cloud, "modulate:a", 0.0, 0.25)
		fade.tween_callback(cloud.queue_free)

# --------------------------------------------------------------- ATTACK 3
## Iron Chain Drag: throws a chain toward the player's current position.
## If the player remains near its line, they are dragged in and hit by the
## follow-up mace strike.
func iron_chain_drag() -> void:
	set_next_attack_delay(3.2)
	var target := player_pos()
	var chain := Line2D.new()
	chain.width = 10.0
	chain.default_color = Color(0.35, 0.19, 0.09, 0.95)
	chain.points = PackedVector2Array([global_position, target])
	chain.z_index = 2
	get_tree().current_scene.add_child(chain)

	if visual:
		visual.modulate = Color(1.45, 0.95, 0.55, 1.0)
	await get_tree().create_timer(0.5).timeout
	if visual:
		visual.modulate = Color(1, 1, 1, 1)

	if is_dead or not is_instance_valid(self):
		chain.queue_free()
		return

	if player_ref and is_instance_valid(player_ref):
		var hit_distance := _distance_to_segment(player_pos(), global_position, target)
		if hit_distance <= 38.0 and global_position.distance_to(player_pos()) <= arena_radius * 1.2:
			var start : Vector2= player_ref.global_position
			var pull_target : Vector2 = global_position + (start - global_position).normalized() * 58.0
			var pull_t := 0.0
			while pull_t < 0.45 and is_instance_valid(player_ref) and not is_dead:
				pull_t += get_physics_process_delta_time()
				player_ref.global_position = start.lerp(pull_target, clamp(pull_t / 0.45, 0.0, 1.0))
				await get_tree().physics_frame

			if is_instance_valid(player_ref) and player_pos().distance_to(global_position) <= 100.0:
				player_ref.take_damage(24.0 * damage_multiplier, self)

	if is_instance_valid(chain):
		chain.queue_free()

# --------------------------------------------------------------- ATTACK 4
## Magnetic Pull: Gideon's charged shield attracts every metallic player
## projectile, then sends it back toward its owner. His "weapon" is also
## magnetically yanked away and snaps back for a small return hit.
func magnetic_pull() -> void:
	set_next_attack_delay(3.9)
	if visual:
		visual.modulate = Color(0.75, 0.9, 1.35, 1.0)

	if player_ref and is_instance_valid(player_ref):
		for projectile in get_tree().get_nodes_in_group("metallic_projectiles"):
			if is_instance_valid(projectile) and projectile.has_method("magnetize_and_return"):
				projectile.magnetize_and_return(self, player_ref, 9.0 * damage_multiplier)
		if player_ref.has_method("magnetic_pull_weapon"):
			player_ref.magnetic_pull_weapon(global_position, 12.0 * damage_multiplier)

	await get_tree().create_timer(0.45).timeout
	if visual:
		visual.modulate = Color(1, 1, 1, 1)

# --------------------------------------------------------------- ATTACK 5
## Fissure Strike: a permanent iron-rending chasm that blocks the player's
## movement. Three fissures are allowed so the arena remains playable.
func fissure_strike() -> void:
	set_next_attack_delay(4.6)
	if fissure_count >= MAX_FISSURES:
		return

	is_busy = true
	if visual:
		visual.modulate = Color(1.5, 0.75, 0.3, 1.0)
	await get_tree().create_timer(0.55).timeout
	if is_dead or not is_instance_valid(self):
		is_busy = false
		return

	var to_player := (player_pos() - global_position).normalized()
	if to_player.length() < 0.01:
		to_player = Vector2.DOWN
	var line_dir := to_player.rotated(PI / 2.0)
	var midpoint := global_position - to_player * 70.0
	_spawn_fissure(midpoint, line_dir)
	if visual:
		visual.modulate = Color(1, 1, 1, 1)
	is_busy = false

func enrage() -> void:
	enraged = true
	damage_multiplier = 1.2
	incoming_damage_multiplier = 0.85
	move_speed += 10.0
	if visual:
		visual.scale = Vector2(1.08, 1.08)

# --------------------------------------------------------------- HELPERS

func _spawn_shockwave(center: Vector2, max_radius: float, duration: float, damage: float) -> void:
	var ring := Line2D.new()
	ring.width = 9.0
	ring.default_color = Color(0.95, 0.48, 0.12, 0.9)
	var points := PackedVector2Array()
	for i in range(49):
		var a := TAU * float(i) / 48.0
		points.append(Vector2(cos(a), sin(a)))
	ring.points = points
	ring.global_position = center
	ring.scale = Vector2.ONE * 0.05
	ring.z_index = 3
	get_tree().current_scene.add_child(ring)

	var t := 0.0
	var previous_radius := max_radius * 0.05
	var hit := false
	while t < duration and is_instance_valid(ring):
		t += get_physics_process_delta_time()
		var ratio :float= clamp(t / duration, 0.0, 1.0)
		var radius : float= lerp(max_radius * 0.05, max_radius, ratio)
		ring.scale = Vector2.ONE * radius
		if not hit and player_ref and is_instance_valid(player_ref):
			var distance := player_pos().distance_to(center)
			if distance >= previous_radius and distance <= radius:
				player_ref.take_damage(damage, self)
				hit = true
		previous_radius = radius
		await get_tree().physics_frame

	if is_instance_valid(ring):
		ring.queue_free()

func _spawn_fissure(midpoint: Vector2, line_dir: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 4
	body.collision_mask = 0
	body.position = midpoint
	body.rotation = line_dir.angle()
	body.z_index = 1

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(arena_radius * 2.4, FISSURE_WIDTH)
	collision.shape = shape
	body.add_child(collision)

	var crack := Line2D.new()
	crack.width = 18.0
	crack.default_color = Color(0.23, 0.12, 0.06, 1.0)
	crack.points = PackedVector2Array([
		Vector2(-arena_radius * 1.2, 0),
		Vector2(arena_radius * 1.2, 0),
	])
	body.add_child(crack)

	var glow := Line2D.new()
	glow.width = 5.0
	glow.default_color = Color(0.95, 0.42, 0.08, 0.85)
	glow.points = crack.points
	body.add_child(glow)

	get_parent().add_child(body)
	fissure_count += 1

func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var length_sq := ab.length_squared()
	if length_sq <= 0.001:
		return point.distance_to(a)
	var t :float= clamp((point - a).dot(ab) / length_sq, 0.0, 1.0)
	return point.distance_to(a.lerp(b, t))
