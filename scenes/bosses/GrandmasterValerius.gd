extends BossBase
class_name GrandmasterValerius

## Grandmaster Valerius, The Echoing Duelist.
## High-mobility boss focused on prediction, telegraphs, pursuit, and arena
## geometry. This replaces the former Umbral Warden in boss slot #3.

const BLINK_COUNT_MIN := 3
const BLINK_COUNT_MAX := 5
const BLINK_TELEGRAPH_TIME := 0.85
const BLINK_DASH_SPEED := 980.0
const VAULT_SHOCKWAVE_RADIUS := 245.0
const CYCLONE_SPEED_MULTIPLIER := 1.12
const CYCLONE_DURATION := 2.4
const PARRY_DURATION := 1.15
const EXECUTION_DAMAGE := 34.0
const PARRY_DAMAGE := 30.0

var parry_active := false
var parry_triggered := false
var afterimage_layer: Node2D = null

func _ready() -> void:
	boss_display_name = "Grandmaster Valerius, The Echoing Duelist"
	max_health = 285.0
	move_speed = 128.0
	attack_pattern = [
		"blink_strike_grid",
		"vaulting_descent",
		"cyclone_chase",
		"echo_parry",
		"boundary_execution",
	]
	super._ready()
	afterimage_layer = Node2D.new()
	afterimage_layer.name = "ValeriusAfterimages"
	get_parent().add_child.call_deferred(afterimage_layer)

func take_damage(amount: float, source: Node = null, is_dot: bool = false) -> void:
	if parry_active and not parry_triggered and not is_dead:
		parry_triggered = true
		parry_active = false
		_execute_parry_counter()
		return
	super.take_damage(amount, source, is_dot)

func enrage() -> void:
	move_speed += 28.0

# --------------------------------------------------------------- ATTACK 1
## Blink Strike Grid: marks a jagged route with visible afterimages, then
## performs a rapid dash through that exact route.
func blink_strike_grid() -> void:
	set_next_attack_delay(3.0)
	is_busy = true
	var path: Array[Vector2] = []
	var point := global_position
	var count := randi_range(BLINK_COUNT_MIN, BLINK_COUNT_MAX)
	for i in range(count):
		var target := player_pos()
		var direction := Vector2.from_angle(randf_range(0.0, TAU))
		var offset := direction * randf_range(arena_radius * 0.35, arena_radius * 0.75)
		var next_point := arena_center + offset
		if i == count - 1:
			next_point = target + Vector2(randf_range(-80.0, 80.0), randf_range(-80.0, 80.0))
		next_point = arena_center + (next_point - arena_center).limit_length(arena_radius * 0.82)
		path.append(next_point)
		point = next_point

	var trail := Line2D.new()
	trail.width = 8.0
	trail.default_color = Color(0.65, 0.85, 1.0, 0.48)
	trail.points = PackedVector2Array([global_position] + path)
	trail.z_index = 1
	get_tree().current_scene.add_child(trail)

	for p in path:
		if is_dead:
			break
		global_position = p
		_spawn_afterimage(p)
		await get_tree().create_timer(BLINK_TELEGRAPH_TIME / float(count)).timeout

	if is_dead:
		trail.queue_free()
		is_busy = false
		return

	var dash_points: Array[Vector2] = [global_position]
	dash_points.append_array(path)
	for i in range(1, dash_points.size()):
		var from := dash_points[i - 1]
		var to := dash_points[i]
		var distance := from.distance_to(to)
		var duration := maxf(0.08, distance / BLINK_DASH_SPEED)
		var elapsed := 0.0
		while elapsed < duration and not is_dead:
			elapsed += get_physics_process_delta_time()
			var ratio := clampf(elapsed / duration, 0.0, 1.0)
			global_position = from.lerp(to, ratio)
			if player_ref and is_instance_valid(player_ref) and player_pos().distance_to(global_position) <= 48.0:
				player_ref.take_damage(18.0 * difficulty_scale, self)
			await get_tree().physics_frame

	if is_instance_valid(trail):
		trail.queue_free()
	is_busy = false

# --------------------------------------------------------------- ATTACK 2
## Vaulting Descent: telegraphs a leap to the arena edge, grows in the air,
## then lands at the player's current position with an expanding shockwave.
func vaulting_descent() -> void:
	set_next_attack_delay(3.2)
	is_busy = true
	var target := player_pos()
	var away := (target - arena_center).normalized()
	if away.length() < 0.1:
		away = Vector2.UP
	var wall_point := arena_center + away * (arena_radius * 0.78)

	_spawn_ground_shadow(wall_point, 28.0)
	if visual:
		visual.modulate = Color(0.55, 0.75, 1.0, 1.0)
	await get_tree().create_timer(0.45).timeout
	if is_dead:
		is_busy = false
		return

	global_position = wall_point
	_spawn_afterimage(wall_point)
	if visual:
		visual.scale = Vector2(1.65, 1.65)
		visual.modulate = Color(0.85, 0.95, 1.0, 1.0)

	await get_tree().create_timer(0.5).timeout
	if is_dead:
		is_busy = false
		return

	var landing := player_pos()
	landing = arena_center + (landing - arena_center).limit_length(arena_radius * 0.82)
	global_position = landing
	if visual:
		visual.scale = Vector2.ONE
		visual.modulate = Color.WHITE
	_spawn_shockwave(landing, VAULT_SHOCKWAVE_RADIUS, 0.72, 20.0 * difficulty_scale)
	is_busy = false

# --------------------------------------------------------------- ATTACK 3
## Cyclone Chase: continuously homes toward the player at a little above the
## player's base movement pace. Contact repeatedly threatens damage.
func cyclone_chase() -> void:
	set_next_attack_delay(3.4)
	is_busy = true
	var duration := CYCLONE_DURATION
	var elapsed := 0.0
	if visual:
		visual.modulate = Color(0.6, 0.85, 1.35, 1.0)
	while elapsed < duration and not is_dead:
		var delta := get_physics_process_delta_time()
		elapsed += delta
		var dir := (player_pos() - global_position).normalized()
		global_position += dir * move_speed * CYCLONE_SPEED_MULTIPLIER * delta
		global_position = arena_center + (global_position - arena_center).limit_length(arena_radius * 0.86)
		rotation += delta * 10.0
		if player_ref and is_instance_valid(player_ref) and player_pos().distance_to(global_position) <= 52.0:
			player_ref.take_damage(7.0 * difficulty_scale * delta * 5.0, self)
		await get_tree().physics_frame
	rotation = 0.0
	if visual:
		visual.modulate = Color.WHITE
	is_busy = false

# --------------------------------------------------------------- ATTACK 4
## Echo Parry: a readable defensive window. A hit during the window causes
## Valerius to vanish and reappear directly behind the player.
func echo_parry() -> void:
	set_next_attack_delay(3.8)
	parry_active = true
	parry_triggered = false
	is_busy = true
	if visual:
		visual.modulate = Color(0.7, 0.9, 1.0, 0.55)
		visual.scale = Vector2(0.9, 0.9)

	var start := global_position
	var glide_target := arena_center + Vector2.from_angle(randf_range(0.0, TAU)) * arena_radius * 0.55
	var elapsed := 0.0
	while elapsed < PARRY_DURATION and not is_dead and not parry_triggered:
		elapsed += get_physics_process_delta_time()
		var ratio := clampf(elapsed / PARRY_DURATION, 0.0, 1.0)
		global_position = start.lerp(glide_target, ratio)
		await get_tree().physics_frame

	if not parry_triggered:
		parry_active = false
		if visual:
			visual.scale = Vector2.ONE
			visual.modulate = Color.WHITE
	is_busy = false

func _execute_parry_counter() -> void:
	is_busy = true
	_spawn_smoke_burst(global_position)
	var target := player_pos()
	var behind := Vector2.DOWN
	if player_ref and is_instance_valid(player_ref):
		var facing_value = player_ref.get("facing")
		if facing_value is Vector2 and facing_value.length() > 0.1:
			behind = facing_value.normalized()
	var counter_pos := target + behind * 62.0
	counter_pos = arena_center + (counter_pos - arena_center).limit_length(arena_radius * 0.84)
	await get_tree().create_timer(0.16).timeout
	if is_dead:
		is_busy = false
		return
	global_position = counter_pos
	_spawn_afterimage(counter_pos)
	if visual:
		visual.scale = Vector2(1.25, 1.25)
	if player_ref and is_instance_valid(player_ref) and player_pos().distance_to(global_position) <= 92.0:
		player_ref.take_damage(PARRY_DAMAGE * difficulty_scale, self)
	await get_tree().create_timer(0.22).timeout
	if visual:
		visual.scale = Vector2.ONE
		visual.modulate = Color.WHITE
	is_busy = false

# --------------------------------------------------------------- ATTACK 5
## Boundary Execution: four phantom copies appear at the corners and all
## five silhouettes converge through the arena in a giant cross telegraph.
func boundary_execution() -> void:
	set_next_attack_delay(4.6)
	is_busy = true
	global_position = arena_center
	var corner_distance := arena_radius * 0.78
	var corners := [
		arena_center + Vector2(-corner_distance, -corner_distance),
		arena_center + Vector2(corner_distance, -corner_distance),
		arena_center + Vector2(corner_distance, corner_distance),
		arena_center + Vector2(-corner_distance, corner_distance),
	]
	var clones: Array[Node2D] = []
	for corner in corners:
		var clone := _spawn_ghost_clone(corner)
		clones.append(clone)

	var cross_lines: Array[Line2D] = []
	for axis in [Vector2(1, 1), Vector2(1, -1)]:
		var line := Line2D.new()
		line.width = 15.0
		line.default_color = Color(0.72, 0.9, 1.0, 0.28)
		line.points = PackedVector2Array([
			arena_center - axis * arena_radius * 1.1,
			arena_center + axis * arena_radius * 1.1,
		])
		line.z_index = 1
		get_tree().current_scene.add_child(line)
		cross_lines.append(line)

	await get_tree().create_timer(0.9).timeout
	if is_dead:
		is_busy = false
		return

	for clone in clones:
		if is_instance_valid(clone):
			var tween := clone.create_tween()
			tween.tween_property(clone, "global_position", arena_center, 0.28)
			clone.modulate = Color(0.75, 0.9, 1.0, 0.65)

	var hit := false
	var elapsed := 0.0
	while elapsed < 0.34 and not is_dead:
		elapsed += get_physics_process_delta_time()
		if player_ref and is_instance_valid(player_ref) and not hit:
			var p := player_pos()
			var d1 := _distance_to_segment(p, arena_center - Vector2.ONE * arena_radius * 1.1, arena_center + Vector2.ONE * arena_radius * 1.1)
			var d2 := _distance_to_segment(p, arena_center - Vector2(arena_radius, -arena_radius) * 1.1, arena_center + Vector2(arena_radius, -arena_radius) * 1.1)
			if minf(d1, d2) <= 34.0:
				player_ref.take_damage(EXECUTION_DAMAGE * difficulty_scale, self)
				hit = true
		await get_tree().physics_frame

	for line in cross_lines:
		if is_instance_valid(line):
			line.queue_free()
	for clone in clones:
		if is_instance_valid(clone):
			clone.queue_free()
	is_busy = false

# --------------------------------------------------------------- VISUAL HELPERS

func _spawn_afterimage(pos: Vector2) -> void:
	if not is_instance_valid(afterimage_layer):
		return
	var ghost := Polygon2D.new()
	ghost.polygon = PackedVector2Array([
		Vector2(0, -30), Vector2(18, -8), Vector2(12, 28),
		Vector2(-12, 28), Vector2(-18, -8)
	])
	ghost.color = Color(0.55, 0.8, 1.0, 0.3)
	ghost.global_position = pos
	afterimage_layer.add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.35)
	tween.tween_callback(ghost.queue_free)

func _spawn_ghost_clone(pos: Vector2) -> Node2D:
	var ghost := Node2D.new()
	ghost.global_position = pos
	ghost.z_index = 2
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(0, -34), Vector2(22, -10), Vector2(16, 30),
		Vector2(-16, 30), Vector2(-22, -10)
	])
	body.color = Color(0.58, 0.82, 1.0, 0.48)
	ghost.add_child(body)
	get_tree().current_scene.add_child(ghost)
	return ghost

func _spawn_ground_shadow(pos: Vector2, radius: float) -> void:
	var shadow := Polygon2D.new()
	var points := PackedVector2Array()
	for i in range(25):
		var a := TAU * float(i) / 24.0
		points.append(Vector2(cos(a) * radius, sin(a) * radius * 0.45))
	shadow.polygon = points
	shadow.color = Color(0.05, 0.08, 0.12, 0.5)
	shadow.global_position = pos
	get_tree().current_scene.add_child(shadow)
	var tween := shadow.create_tween()
	tween.tween_property(shadow, "scale", Vector2(3.2, 3.2), 0.85)
	tween.tween_property(shadow, "modulate:a", 0.0, 0.25)
	tween.tween_callback(shadow.queue_free)

func _spawn_smoke_burst(pos: Vector2) -> void:
	var smoke := Polygon2D.new()
	smoke.polygon = PackedVector2Array([
		Vector2(-28, 0), Vector2(-10, -24), Vector2(18, -22),
		Vector2(32, 0), Vector2(14, 24), Vector2(-18, 20)
	])
	smoke.color = Color(0.25, 0.3, 0.38, 0.72)
	smoke.global_position = pos
	get_tree().current_scene.add_child(smoke)
	var tween := smoke.create_tween()
	tween.tween_property(smoke, "scale", Vector2(1.8, 1.8), 0.28)
	tween.tween_property(smoke, "modulate:a", 0.0, 0.25)
	tween.tween_callback(smoke.queue_free)

func _spawn_shockwave(center: Vector2, max_radius: float, duration: float, damage: float) -> void:
	var ring := Line2D.new()
	ring.width = 10.0
	ring.default_color = Color(0.6, 0.85, 1.0, 0.88)
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
		var ratio := clampf(t / duration, 0.0, 1.0)
		var radius := lerpf(max_radius * 0.05, max_radius, ratio)
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

func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var length_sq := ab.length_squared()
	if length_sq <= 0.001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / length_sq, 0.0, 1.0)
	return point.distance_to(a.lerp(b, t))
