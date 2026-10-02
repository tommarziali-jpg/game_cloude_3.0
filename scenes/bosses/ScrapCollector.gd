extends BossBase
class_name ScrapCollector

## The Scrap Collector: Scraptooth, The Junk Magnet
## Design/lore floor: 19.5. The current tower uses integer boss floors,
## replacing Static Sovereign keeps this encounter on playable Floor 45.

const DEBRIS_LAYER := 4
const JUNK_COLORS := [
	Color(0.42, 0.44, 0.46, 1.0),
	Color(0.58, 0.39, 0.20, 1.0),
	Color(0.30, 0.33, 0.35, 1.0),
	Color(0.65, 0.57, 0.35, 1.0)
]

var active_junk: Array[Node2D] = []
var shield_junk: Array[Node2D] = []
var _attack_junk_cache: Array[Node2D] = []
var _shield_active := false

func _ready() -> void:
	boss_display_name = "The Scrap Collector: Scraptooth, The Junk Magnet"
	max_health = 330.0
	move_speed = 82.0
	attack_pattern = [
		"junk_throw",
		"magnetic_recall",
		"shrapnel_shield",
		"iron_hail",
		"scrap_engine_dash",
	]
	super._ready()
	queue_redraw()

func _draw() -> void:
	# Large junk-heap silhouette with a visible magnetic core and limbs.
	draw_circle(Vector2.ZERO, 48.0, Color(0.18, 0.19, 0.20, 1.0))
	draw_circle(Vector2.ZERO, 24.0, Color(0.75, 0.62, 0.24, 1.0))
	draw_circle(Vector2.ZERO, 13.0, Color(0.20, 0.65, 0.75, 1.0))
	draw_line(Vector2(-62, -18), Vector2(-38, -6), Color(0.55, 0.37, 0.20), 11.0)
	draw_line(Vector2(62, -18), Vector2(38, -6), Color(0.55, 0.37, 0.20), 11.0)
	draw_line(Vector2(-42, 35), Vector2(-24, 50), Color(0.38, 0.40, 0.42), 13.0)
	draw_line(Vector2(42, 35), Vector2(24, 50), Color(0.38, 0.40, 0.42), 13.0)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	queue_redraw()

func _die() -> void:
	_cleanup_junk()
	super._die()

func _cleanup_junk() -> void:
	for junk in active_junk:
		if is_instance_valid(junk):
			junk.queue_free()
	for junk in shield_junk:
		if is_instance_valid(junk):
			junk.queue_free()
	active_junk.clear()
	shield_junk.clear()

func _make_junk(pos: Vector2, size: float = 30.0) -> Node2D:
	var body := StaticBody2D.new()
	body.name = "ScrapDebris"
	body.collision_layer = DEBRIS_LAYER
	body.collision_mask = 2
	body.global_position = pos
	body.rotation = randf_range(0.0, TAU)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size * 1.35, size * 0.75)
	shape.shape = rect
	body.add_child(shape)

	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-size * 0.68, -size * 0.30),
		Vector2(-size * 0.30, -size * 0.60),
		Vector2(size * 0.62, -size * 0.42),
		Vector2(size * 0.70, size * 0.25),
		Vector2(size * 0.22, size * 0.58),
		Vector2(-size * 0.62, size * 0.48)
	])
	visual.color = JUNK_COLORS[randi() % JUNK_COLORS.size()]
	body.add_child(visual)

	var bolt := Polygon2D.new()
	bolt.polygon = PackedVector2Array([
		Vector2(-5, -5), Vector2(5, -5), Vector2(7, 0),
		Vector2(5, 5), Vector2(-5, 5), Vector2(-7, 0)
	])
	bolt.color = Color(0.75, 0.76, 0.72, 1.0)
	bolt.position = Vector2(size * 0.22, -size * 0.08)
	body.add_child(bolt)

	get_tree().current_scene.add_child(body)
	active_junk.append(body)
	return body

func _remove_junk(junk: Node2D) -> void:
	active_junk.erase(junk)
	shield_junk.erase(junk)
	if is_instance_valid(junk):
		junk.queue_free()

# --------------------------------------------------------------- ATTACK 1
## Junk Throw: three heavy scrap chunks land at three nearby target points.
func junk_throw() -> void:
	set_next_attack_delay(3.4)
	is_busy = true
	var target := player_pos()
	var offsets := [
		Vector2(-65, -30),
		Vector2(0, 20),
		Vector2(65, -30)
	]
	var thrown: Array[Node2D] = []

	for offset in offsets:
		var marker := _warning_circle(target + offset, 26.0, Color(0.95, 0.55, 0.18, 0.65))
		await get_tree().create_timer(0.18).timeout
		if is_instance_valid(marker):
			marker.queue_free()
		var junk := _make_junk(target + offset, randf_range(28.0, 42.0))
		junk.scale = Vector2(0.25, 0.25)
		thrown.append(junk)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(junk, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK)
		tween.tween_property(junk, "rotation", junk.rotation + randf_range(1.5, 3.5), 0.28)

		if player_ref and player_pos().distance_to(junk.global_position) < 48.0:
			player_ref.take_damage(15.0 * difficulty_scale, self)

	is_busy = false

# --------------------------------------------------------------- ATTACK 2
## Magnetic Recall: every loose chunk visibly accelerates toward the boss.
func magnetic_recall() -> void:
	set_next_attack_delay(3.8)
	is_busy = true
	var center := global_position
	var junk_to_recall: Array[Node2D] = []
	for junk in active_junk:
		if is_instance_valid(junk):
			junk_to_recall.append(junk)

	var core := _warning_circle(center, 55.0, Color(0.25, 0.85, 0.95, 0.85))
	var elapsed := 0.0
	while elapsed < 0.45:
		elapsed += get_physics_process_delta_time()
		if is_instance_valid(core):
			core.scale = Vector2.ONE * (1.0 + elapsed * 1.2)
		await get_tree().physics_frame

	for junk in junk_to_recall:
		if not is_instance_valid(junk):
			continue
		var tween := create_tween()
		tween.tween_property(junk, "global_position", center, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(junk, "rotation", junk.rotation + TAU, 0.42)
		await get_tree().create_timer(0.05).timeout

	var path_time := 0.5
	var t := 0.0
	while t < path_time:
		t += get_physics_process_delta_time()
		if player_ref and player_ref.global_position.distance_to(center) < 90.0:
			# The danger is the converging return path, not the core itself.
			var nearest := _nearest_recall_segment_point(player_ref.global_position, junk_to_recall, center)
			if player_ref.global_position.distance_to(nearest) < 48.0:
				player_ref.take_damage(18.0 * difficulty_scale * get_physics_process_delta_time(), self)
		await get_tree().physics_frame

	for junk in junk_to_recall:
		_remove_junk(junk)
	if is_instance_valid(core):
		core.queue_free()
	is_busy = false

func _nearest_recall_segment_point(point: Vector2, junk_list: Array[Node2D], center: Vector2) -> Vector2:
	var best := center
	var best_dist := INF
	for junk in junk_list:
		if not is_instance_valid(junk):
			continue
		var candidate := _closest_point_on_segment(point, junk.global_position, center)
		var d := point.distance_to(candidate)
		if d < best_dist:
			best_dist = d
			best = candidate
	return best

# --------------------------------------------------------------- ATTACK 3
## Shrapnel Shield: four chunks orbit tightly, making melee contact dangerous.
func shrapnel_shield() -> void:
	set_next_attack_delay(3.6)
	is_busy = true
	_shield_active = true
	shield_junk.clear()

	var count := 4
	for i in range(count):
		var junk := _make_junk(global_position + Vector2.from_angle(TAU * i / count) * 82.0, 27.0)
		shield_junk.append(junk)

	var elapsed := 0.0
	var duration := 2.2
	while elapsed < duration and not is_dead:
		var delta := get_physics_process_delta_time()
		elapsed += delta
		for i in range(shield_junk.size()):
			var junk := shield_junk[i]
			if not is_instance_valid(junk):
				continue
			var angle := elapsed * 4.2 + TAU * i / float(count)
			junk.global_position = global_position + Vector2.from_angle(angle) * 88.0
			junk.rotation += delta * 6.0
			if player_ref and player_pos().distance_to(junk.global_position) < 34.0:
				player_ref.take_damage(7.0 * difficulty_scale * delta * 5.0, self)
		if player_ref and player_pos().distance_to(global_position) < 78.0:
			player_ref.take_damage(12.0 * difficulty_scale * delta, self)
		await get_tree().physics_frame

	for junk in shield_junk.duplicate():
		_remove_junk(junk)
	shield_junk.clear()
	_shield_active = false
	is_busy = false

# --------------------------------------------------------------- ATTACK 4
## Iron Hail: many small warning circles appear, then bolts drop from above.
func iron_hail() -> void:
	set_next_attack_delay(4.0)
	is_busy = true
	var zones: Array[Node2D] = []
	for i in range(28):
		var angle := randf_range(0.0, TAU)
		var radius := randf_range(35.0, arena_radius * 0.92)
		var pos := arena_center + Vector2.from_angle(angle) * radius
		zones.append(_warning_circle(pos, randf_range(9.0, 16.0), Color(0.85, 0.72, 0.32, 0.75)))

	await get_tree().create_timer(0.9).timeout
	for zone in zones:
		if is_instance_valid(zone):
			var strike_pos := zone.global_position
			if player_ref and player_pos().distance_to(strike_pos) < 20.0:
				player_ref.take_damage(10.0 * difficulty_scale, self)
			var bolt := _make_hail_bolt(strike_pos)
			var tween := create_tween()
			tween.tween_property(bolt, "scale", Vector2(1.8, 1.8), 0.18)
			tween.tween_property(bolt, "modulate:a", 0.0, 0.16)
			tween.tween_callback(bolt.queue_free)
			zone.queue_free()
	is_busy = false

func _make_hail_bolt(pos: Vector2) -> Node2D:
	var bolt := Polygon2D.new()
	bolt.polygon = PackedVector2Array([
		Vector2(-5, -5), Vector2(5, -5), Vector2(7, 0),
		Vector2(5, 5), Vector2(-5, 5), Vector2(-7, 0)
	])
	bolt.color = Color(0.72, 0.74, 0.78, 0.95)
	bolt.global_position = pos
	get_tree().current_scene.add_child(bolt)
	return bolt

# --------------------------------------------------------------- ATTACK 5
## Scrap Engine Dash: a loud, visible straight charge. Any junk touched is
## kicked toward the player's current position while Scraptooth continues.
func scrap_engine_dash() -> void:
	set_next_attack_delay(4.2)
	is_busy = true
	var start := global_position
	var dir := (player_pos() - start).normalized()
	if dir.length() < 0.01:
		dir = Vector2.RIGHT

	var telegraph := _dash_line(start, start + dir * arena_radius, 0.0)
	await get_tree().create_timer(0.65).timeout
	if is_instance_valid(telegraph):
		telegraph.queue_free()

	var elapsed := 0.0
	var duration := 0.75
	while elapsed < duration and not is_dead:
		var delta := get_physics_process_delta_time()
		elapsed += delta
		var old_pos := global_position
		global_position += dir * 430.0 * delta
		global_position = arena_center + (global_position - arena_center).limit_length(arena_radius * 0.92)

		if player_ref and player_pos().distance_to(global_position) < 55.0:
			player_ref.take_damage(20.0 * difficulty_scale * delta * 4.0, self)

		for junk in active_junk.duplicate():
			if not is_instance_valid(junk):
				continue
			if old_pos.distance_to(junk.global_position) < 58.0 or global_position.distance_to(junk.global_position) < 58.0:
				var kicked := junk.global_position
				_remove_junk(junk)
				_launch_scrap_projectile(kicked, player_pos())

		await get_tree().physics_frame

	is_busy = false

func _launch_scrap_projectile(origin: Vector2, target: Vector2) -> void:
	var scrap := _make_hail_bolt(origin)
	scrap.scale = Vector2(1.8, 1.8)
	var direction := (target - origin).normalized()
	var end := origin + direction * 560.0
	var tween := create_tween()
	tween.tween_property(scrap, "global_position", end, 0.72).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func():
		if is_instance_valid(scrap):
			scrap.queue_free()
	)
	if player_ref:
		var hit_tween := create_tween()
		hit_tween.tween_interval(0.25)
		hit_tween.tween_callback(func():
			if is_instance_valid(player_ref) and is_instance_valid(scrap) and player_ref.global_position.distance_to(scrap.global_position) < 34.0:
				player_ref.take_damage(16.0 * difficulty_scale, self)
		)

func _warning_circle(pos: Vector2, radius: float, color: Color) -> Node2D:
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = color
	var points := PackedVector2Array()
	for i in range(33):
		var a := TAU * float(i) / 32.0
		points.append(Vector2(cos(a), sin(a)) * radius)
	ring.points = points
	ring.global_position = pos
	get_tree().current_scene.add_child(ring)
	return ring

func _dash_line(a: Vector2, b: Vector2, _unused: float) -> Line2D:
	var line := Line2D.new()
	line.width = 10.0
	line.default_color = Color(0.92, 0.48, 0.18, 0.75)
	line.points = PackedVector2Array([a, b])
	get_tree().current_scene.add_child(line)
	return line

func _closest_point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	var denom := ab.length_squared()
	if denom <= 0.001:
		return a
	var t := clampf((p - a).dot(ab) / denom, 0.0, 1.0)
	return a + ab * t

func enrage() -> void:
	move_speed += 28.0
	max_health += 0.0
	queue_redraw()
