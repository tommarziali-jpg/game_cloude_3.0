extends BossBase
class_name MasonPrime

## The Architect's Golem: The Mason-Prime
## Floor 5.5 is the lore/design label for this boss. In the integer floor
## rotation it replaces the former Hollow Chorister slot.
##
## VISUAL MAPPING
## - Body: a floating torso made from rigid rectangular tower bricks.
## - Monolithic Charge: bricks lock into one broad rectangular ram-shield;
##   a short dust trail follows the charge.
## - Centrifugal Mortar-Spin: two detached brick fists orbit the torso.
## - Tectonic Wave-Glide: the core flattens visually and sends expanding
##   ripple rings across the floor.
## - Pillar Orbit: four tall stone pillars detach from the body and orbit it.
## - Architect's Gridlock: glowing blueprint rows/columns appear on the floor,
##   then flash upward as rectangular light pillars.
##
## The permanent tower floor is never modified; every masonry effect is a
## temporary visual/hazard object.

const CHARGE_DISTANCE: float = 420.0
const ORBIT_RADIUS: float = 125.0
const GRID_RADIUS: float = 245.0

func _ready() -> void:
	boss_display_name = "The Architect's Golem: The Mason-Prime"
	max_health = 320.0
	move_speed = 88.0
	attack_pattern = [
		"monolithic_charge",
		"centrifugal_mortar_spin",
		"tectonic_wave_glide",
		"pillar_orbit",
		"architects_gridlock",
	]
	super._ready()
	queue_redraw()

func _draw() -> void:
	# Visual identity: several rigid stone bricks form a floating torso.
	var brick := Color(0.28, 0.29, 0.31, 1.0)
	var mortar := Color(0.12, 0.13, 0.14, 1.0)
	draw_rect(Rect2(-48, -52, 96, 104), mortar)
	draw_rect(Rect2(-42, -46, 84, 28), brick)
	draw_rect(Rect2(-42, -14, 40, 28), brick)
	draw_rect(Rect2(2, -14, 40, 28), brick)
	draw_rect(Rect2(-42, 18, 84, 28), brick)
	draw_line(Vector2(-42, -18), Vector2(42, -18), Color(0.1, 0.1, 0.11, 1.0), 3.0)
	draw_line(Vector2(-42, 18), Vector2(42, 18), Color(0.1, 0.1, 0.11, 1.0), 3.0)

# --------------------------------------------------------------- ATTACK 1
## Monolithic Charge: the torso compresses into a dense rectangular ram.
func monolithic_charge() -> void:
	set_next_attack_delay(3.8)
	is_busy = true
	var start: Vector2 = global_position
	var dir: Vector2 = (player_pos() - start).normalized()
	if dir.length() < 0.01:
		dir = Vector2.RIGHT

	var shield := Polygon2D.new()
	shield.polygon = PackedVector2Array([
		Vector2(-58, -48), Vector2(58, -48), Vector2(58, 48), Vector2(-58, 48)
	])
	shield.color = Color(0.34, 0.35, 0.37, 1.0)
	shield.global_position = start + dir * 18.0
	shield.rotation = dir.angle()
	get_tree().current_scene.add_child(shield)

	if visual:
		visual.modulate = Color(0.8, 0.82, 0.86, 1.0)
		visual.scale = Vector2(1.2, 1.2)

	await get_tree().create_timer(0.45).timeout
	var end_pos: Vector2 = start + dir * CHARGE_DISTANCE
	var t: float = 0.0
	var duration: float = 0.5
	while t < duration and not is_dead:
		t += get_physics_process_delta_time()
		global_position = start.lerp(end_pos, clampf(t / duration, 0.0, 1.0))
		shield.global_position = global_position + dir * 18.0
		_spawn_dust(global_position - dir * 45.0)
		if player_ref and player_pos().distance_to(global_position) < 62.0:
			player_ref.take_damage(20.0 * difficulty_scale, self)
		await get_tree().physics_frame

	if is_instance_valid(shield):
		shield.queue_free()
	if visual:
		visual.modulate = Color.WHITE
		visual.scale = Vector2.ONE
	is_busy = false

# --------------------------------------------------------------- ATTACK 2
## Centrifugal Mortar-Spin: two fists detach and orbit while the torso glides.
func centrifugal_mortar_spin() -> void:
	set_next_attack_delay(3.8)
	is_busy = true
	var fists: Array[Polygon2D] = []
	for side in [-1.0, 1.0]:
		var fist := Polygon2D.new()
		fist.polygon = PackedVector2Array([
			Vector2(-24, -24), Vector2(24, -24), Vector2(24, 24), Vector2(-24, 24)
		])
		fist.color = Color(0.32, 0.33, 0.35, 1.0)
		get_tree().current_scene.add_child(fist)
		fists.append(fist)

	var elapsed: float = 0.0
	var duration: float = 2.2
	while elapsed < duration and not is_dead:
		var delta: float = get_physics_process_delta_time()
		elapsed += delta
		global_position += (player_pos() - global_position).normalized() * move_speed * 0.72 * delta
		global_position = arena_center + (global_position - arena_center).limit_length(arena_radius * 0.8)
		var angle: float = elapsed * 5.5
		for i in range(fists.size()):
			var offset: Vector2 = Vector2.from_angle(angle + PI * float(i)) * ORBIT_RADIUS
			fists[i].global_position = global_position + offset
			fists[i].rotation = angle * 1.8
			if player_ref and player_pos().distance_to(fists[i].global_position) < 38.0:
				player_ref.take_damage(8.0 * difficulty_scale * delta * 5.0, self)
		await get_tree().physics_frame

	for fist in fists:
		if is_instance_valid(fist):
			fist.queue_free()
	is_busy = false

# --------------------------------------------------------------- ATTACK 3
## Tectonic Wave-Glide: a flat core slam followed by a traveling floor ripple.
func tectonic_wave_glide() -> void:
	set_next_attack_delay(3.6)
	is_busy = true
	if visual:
		visual.scale = Vector2(1.45, 0.65)
		visual.modulate = Color(0.65, 0.7, 0.76, 1.0)
	await get_tree().create_timer(0.35).timeout
	if visual:
		visual.scale = Vector2.ONE
		visual.modulate = Color.WHITE

	var center: Vector2 = global_position
	var ring := Line2D.new()
	ring.width = 8.0
	ring.default_color = Color(0.55, 0.68, 0.78, 0.9)
	var points := PackedVector2Array()
	for i in range(49):
		var a: float = TAU * float(i) / 48.0
		points.append(Vector2(cos(a), sin(a)))
	ring.points = points
	ring.global_position = center
	ring.scale = Vector2.ONE * 0.05
	get_tree().current_scene.add_child(ring)

	var elapsed: float = 0.0
	var duration: float = 0.9
	var previous_radius: float = 12.0
	var hit: bool = false
	while elapsed < duration and is_instance_valid(ring) and not is_dead:
		elapsed += get_physics_process_delta_time()
		var radius: float = lerpf(12.0, arena_radius * 0.95, clampf(elapsed / duration, 0.0, 1.0))
		ring.scale = Vector2.ONE * radius
		if not hit and player_ref:
			var dist: float = player_pos().distance_to(center)
			if dist >= previous_radius and dist <= radius:
				player_ref.take_damage(18.0 * difficulty_scale, self)
				hit = true
		previous_radius = radius
		await get_tree().physics_frame

	if is_instance_valid(ring):
		ring.queue_free()
	is_busy = false

# --------------------------------------------------------------- ATTACK 4
## Pillar Orbit: four vertical stone columns detach and rotate as a cage.
func pillar_orbit() -> void:
	set_next_attack_delay(4.0)
	is_busy = true
	var pillars: Array[Polygon2D] = []
	for i in range(4):
		var pillar := Polygon2D.new()
		pillar.polygon = PackedVector2Array([
			Vector2(-16, -52), Vector2(16, -52), Vector2(16, 52), Vector2(-16, 52)
		])
		pillar.color = Color(0.38, 0.39, 0.41, 1.0)
		get_tree().current_scene.add_child(pillar)
		pillars.append(pillar)

	var elapsed: float = 0.0
	var duration: float = 2.5
	while elapsed < duration and not is_dead:
		var delta: float = get_physics_process_delta_time()
		elapsed += delta
		global_position += (player_pos() - global_position).normalized() * move_speed * 0.55 * delta
		global_position = arena_center + (global_position - arena_center).limit_length(arena_radius * 0.78)
		for i in range(pillars.size()):
			var angle: float = elapsed * 2.7 + TAU * float(i) / 4.0
			pillars[i].global_position = global_position + Vector2.from_angle(angle) * 105.0
			pillars[i].rotation = angle
			if player_ref and player_pos().distance_to(pillars[i].global_position) < 34.0:
				player_ref.take_damage(6.0 * difficulty_scale * delta * 5.0, self)
		await get_tree().physics_frame

	for pillar in pillars:
		if is_instance_valid(pillar):
			pillar.queue_free()
	is_busy = false

# --------------------------------------------------------------- ATTACK 5
## Architect's Gridlock: blueprint rows/columns charge, then erupt as light.
func architects_gridlock() -> void:
	set_next_attack_delay(4.8)
	is_busy = true
	var lines: Array[Line2D] = []
	var radius: float = GRID_RADIUS
	for i in range(5):
		var x: float = lerpf(-radius, radius, float(i) / 4.0)
		var line := _blueprint_line(
			arena_center + Vector2(x, -radius),
			arena_center + Vector2(x, radius)
		)
		lines.append(line)
	for i in range(5):
		var y: float = lerpf(-radius, radius, float(i) / 4.0)
		var line := _blueprint_line(
			arena_center + Vector2(-radius, y),
			arena_center + Vector2(radius, y)
		)
		lines.append(line)

	var retreat: Vector2 = (global_position - player_pos()).normalized()
	if retreat.length() < 0.01:
		retreat = Vector2.UP
	var start: Vector2 = global_position
	var end_pos: Vector2 = start + retreat * 150.0
	var elapsed: float = 0.0
	while elapsed < 0.7 and not is_dead:
		elapsed += get_physics_process_delta_time()
		global_position = start.lerp(end_pos, clampf(elapsed / 0.7, 0.0, 1.0))
		await get_tree().physics_frame

	await get_tree().create_timer(0.35).timeout
	for line in lines:
		if is_instance_valid(line):
			line.default_color = Color(0.65, 0.85, 1.0, 0.95)

	for i in range(5):
		var x: float = lerpf(-radius, radius, float(i) / 4.0)
		_spawn_light_column(arena_center + Vector2(x, 0.0))
	for i in range(5):
		var y: float = lerpf(-radius, radius, float(i) / 4.0)
		_spawn_light_column(arena_center + Vector2(0.0, y))

	for line in lines:
		if is_instance_valid(line):
			var fade := create_tween()
			fade.tween_property(line, "modulate:a", 0.0, 0.35)
			fade.tween_callback(line.queue_free)
	is_busy = false

func _blueprint_line(a: Vector2, b: Vector2) -> Line2D:
	var line := Line2D.new()
	line.width = 4.0
	line.default_color = Color(0.25, 0.6, 0.95, 0.55)
	line.points = PackedVector2Array([a, b])
	get_tree().current_scene.add_child(line)
	return line

func _spawn_light_column(pos: Vector2) -> void:
	var column := Polygon2D.new()
	column.polygon = PackedVector2Array([
		Vector2(-12, -48), Vector2(12, -48), Vector2(12, 48), Vector2(-12, 48)
	])
	column.color = Color(0.6, 0.82, 1.0, 0.85)
	column.global_position = pos
	get_tree().current_scene.add_child(column)
	var tw := create_tween()
	tw.tween_property(column, "scale", Vector2(1.4, 1.4), 0.16)
	tw.tween_property(column, "modulate:a", 0.0, 0.28)
	tw.tween_callback(column.queue_free)

func _spawn_dust(pos: Vector2) -> void:
	var dust := Polygon2D.new()
	dust.polygon = PackedVector2Array([
		Vector2(-18, -8), Vector2(18, -8), Vector2(26, 8), Vector2(-26, 8)
	])
	dust.color = Color(0.45, 0.43, 0.4, 0.5)
	dust.global_position = pos
	get_tree().current_scene.add_child(dust)
	var tw := create_tween()
	tw.tween_property(dust, "scale", Vector2(1.8, 1.8), 0.22)
	tw.tween_property(dust, "modulate:a", 0.0, 0.2)
	tw.tween_callback(dust.queue_free)
