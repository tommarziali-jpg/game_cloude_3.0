extends BossBase
class_name SolarSentinel

## The Solar Sentinel: Ignis, The Focused Ray
## Boss #10 -- Floors 50, 100, 150...
## Theme: orbital tracks, safe zones, heat buildup, and readable light hazards.

var heat_buildup: float = 0.0
var orbital_angle: float = 0.0
var heat_ring: Line2D = null

func _ready() -> void:
	boss_display_name = "The Solar Sentinel: Ignis, The Focused Ray"
	max_health = 360.0
	move_speed = 62.0
	attack_pattern = [
		"orbital_orbs",
		"solar_flare_cross",
		"tracking_death_beam",
		"blinding_eclipse",
		"supernova_pulsar",
	]
	super._ready()
	_build_construct_visuals()

func _build_construct_visuals() -> void:
	# Three concentric astrolabe rings make the boss readable even without textures.
	for ring_data in [[58.0, 2.0, Color(1.0, 0.78, 0.18, 0.7)],
			[78.0, 3.0, Color(1.0, 0.9, 0.35, 0.52)],
			[105.0, 2.0, Color(0.75, 0.58, 0.18, 0.38)]]:
		var ring := Line2D.new()
		var points := PackedVector2Array()
		var radius: float = ring_data[0]
		for i in range(49):
			var a := TAU * float(i) / 48.0
			points.append(Vector2(cos(a), sin(a)) * radius)
		ring.points = points
		ring.width = ring_data[1]
		ring.default_color = ring_data[2]
		ring.antialiased = true
		$Visual.add_child(ring)

	var spokes := Node2D.new()
	spokes.name = "AstrolabeSpokes"
	$Visual.add_child(spokes)
	for i in range(8):
		var a := TAU * float(i) / 8.0
		_make_line(spokes, Vector2(cos(a), sin(a)) * 30.0, Vector2(cos(a), sin(a)) * 98.0, 2.0, Color(1.0, 0.85, 0.3, 0.45))

	heat_ring = Line2D.new()
	var heat_points := PackedVector2Array()
	for i in range(49):
		var a := TAU * float(i) / 48.0
		heat_points.append(Vector2(cos(a), sin(a)) * 47.0)
	heat_ring.points = heat_points
	heat_ring.width = 5.0
	heat_ring.default_color = Color(1.0, 0.18, 0.05, 0.9)
	heat_ring.antialiased = true
	$Visual.add_child(heat_ring)

func _physics_process(delta: float) -> void:
	heat_buildup = max(0.0, heat_buildup - delta * 4.0)
	if heat_ring and is_instance_valid(heat_ring):
		heat_ring.modulate.a = 0.18 + heat_buildup / 100.0 * 0.82
		heat_ring.scale = Vector2.ONE * (1.0 + heat_buildup / 100.0 * 0.16)
	super._physics_process(delta)

func _add_heat(amount: float) -> void:
	heat_buildup = min(100.0, heat_buildup + amount)

func _damage_player(amount: float) -> void:
	if player_ref and is_instance_valid(player_ref) and player_ref.has_method("take_damage"):
		var heat_multiplier := 1.0 + heat_buildup * 0.0015
		player_ref.take_damage(amount * difficulty_scale * heat_multiplier, self)

func _make_circle(parent: Node, radius: float, sides: int, fill: Color, outline: Color = Color.TRANSPARENT) -> Polygon2D:
	var p := Polygon2D.new()
	var points := PackedVector2Array()
	for i in range(sides):
		var a := TAU * float(i) / float(sides)
		points.append(Vector2(cos(a), sin(a)) * radius)
	p.polygon = points
	p.color = fill
	parent.add_child(p)
	if outline.a > 0.0:
		var ring := Line2D.new()
		var ring_points := PackedVector2Array(points)
		ring_points.append(points[0])
		ring.points = ring_points
		ring.width = 4.0
		ring.default_color = outline
		ring.antialiased = true
		parent.add_child(ring)
	return p

func _make_line(parent: Node, a: Vector2, b: Vector2, width: float, color: Color) -> Line2D:
	var line := Line2D.new()
	line.points = PackedVector2Array([a, b])
	line.width = width
	line.default_color = color
	line.antialiased = true
	parent.add_child(line)
	return line

func _point_to_segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq <= 0.001:
		return point.distance_to(a)
	var t := clamp((point - a).dot(ab) / len_sq, 0.0, 1.0)
	return point.distance_to(a + ab * t)

func _arena_edge(direction: Vector2) -> Vector2:
	return global_position + direction.normalized() * (arena_radius + 80.0)

# --------------------------------------------------------------- ATTACK 1
## Four burning orbs rotate around Ignis on an expanding orbital track.
func orbital_orbs() -> void:
	set_next_attack_delay(2.0)
	is_busy = true
	_add_heat(10.0)

	var fx := Node2D.new()
	fx.name = "OrbitalOrbs"
	get_parent().add_child(fx)

	var orbs: Array[Polygon2D] = []
	for i in range(4):
		orbs.append(_make_circle(fx, 15.0, 16, Color(1.0, 0.55, 0.08, 0.98), Color(1.0, 0.95, 0.35, 1.0)))

	var t := 0.0
	while t < 2.7 and is_instance_valid(self) and not is_dead:
		var delta := get_physics_process_delta_time()
		t += delta
		orbital_angle += delta * 2.7
		var radius := lerp(82.0, 205.0, min(t / 2.7, 1.0))
		for i in range(orbs.size()):
			var a := orbital_angle + TAU * float(i) / 4.0
			orbs[i].global_position = global_position + Vector2(cos(a), sin(a)) * radius
			if player_ref and is_instance_valid(player_ref) and player_ref.global_position.distance_to(orbs[i].global_position) < 27.0:
				_damage_player(18.0 * delta)
		await get_tree().physics_frame

	if is_instance_valid(fx):
		fx.queue_free()
	is_busy = false

# --------------------------------------------------------------- ATTACK 2
## A two-second ground telegraph in a crosshair shape, followed by light pillars.
func solar_flare_cross() -> void:
	set_next_attack_delay(2.0)
	is_busy = true
	_add_heat(15.0)

	var fx := Node2D.new()
	fx.name = "SolarFlareCross"
	get_parent().add_child(fx)

	var vertical := _make_line(fx, global_position + Vector2(0, -arena_radius), global_position + Vector2(0, arena_radius), 7.0, Color(1.0, 0.82, 0.18, 0.5))
	var horizontal := _make_line(fx, global_position + Vector2(-arena_radius, 0), global_position + Vector2(arena_radius, 0), 7.0, Color(1.0, 0.82, 0.18, 0.5))
	var center := _make_circle(fx, 34.0, 24, Color(1.0, 0.9, 0.25, 0.18), Color(1.0, 0.95, 0.55, 0.9))

	var t := 0.0
	while t < 2.0 and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		var pulse := 0.35 + 0.45 * sin(t * 10.0) * sin(t * 10.0)
		vertical.modulate.a = pulse
		horizontal.modulate.a = pulse
		center.scale = Vector2.ONE * (1.0 + t * 0.18)
		await get_tree().physics_frame

	if player_ref and is_instance_valid(player_ref):
		var p := player_ref.global_position - global_position
		if abs(p.x) < 30.0 or abs(p.y) < 30.0:
			_damage_player(34.0)

	vertical.width = 34.0
	horizontal.width = 34.0
	vertical.default_color = Color(1.0, 0.95, 0.55, 0.95)
	horizontal.default_color = Color(1.0, 0.95, 0.55, 0.95)
	center.color = Color(1.0, 1.0, 0.8, 0.95)
	await get_tree().create_timer(0.55).timeout

	if is_instance_valid(fx):
		fx.queue_free()
	is_busy = false

# --------------------------------------------------------------- ATTACK 3
## A thin red targeting line locks on first; the thick beam then tracks the player.
func tracking_death_beam() -> void:
	set_next_attack_delay(2.0)
	is_busy = true
	_add_heat(20.0)

	var fx := Node2D.new()
	fx.name = "TrackingDeathBeam"
	get_parent().add_child(fx)

	var target_line := _make_line(fx, global_position, _arena_edge(Vector2.DOWN), 4.0, Color(1.0, 0.12, 0.12, 0.95))
	var target_dot := _make_circle(fx, 11.0, 20, Color(1.0, 0.08, 0.08, 0.9), Color(1.0, 0.55, 0.55, 1.0))

	var t := 0.0
	while t < 0.75 and is_instance_valid(self) and not is_dead:
		t += get_physics_process_delta_time()
		var dir := (player_pos() - global_position).normalized()
		target_line.points = PackedVector2Array([global_position, _arena_edge(dir)])
		target_dot.global_position = player_pos()
		await get_tree().physics_frame

	target_line.width = 34.0
	target_line.default_color = Color(1.0, 0.65, 0.12, 0.88)

	t = 0.0
	while t < 2.4 and is_instance_valid(self) and not is_dead:
		var delta := get_physics_process_delta_time()
		t += delta
		var dir := (player_pos() - global_position).normalized()
		var end := _arena_edge(dir)
		target_line.points = PackedVector2Array([global_position, end])
		target_dot.global_position = player_pos()
		if _point_to_segment_distance(player_pos(), global_position, end) < 42.0:
			_damage_player(24.0 * delta)
		await get_tree().physics_frame

	if is_instance_valid(fx):
		fx.queue_free()
	is_busy = false

# --------------------------------------------------------------- ATTACK 4
## The dark dome creates an inside/outside choice: inside is slow; outside is
## pressured by fast radial projectiles from Ignis.
func blinding_eclipse() -> void:
	set_next_attack_delay(2.2)
	is_busy = true
	_add_heat(18.0)

	var fx := Node2D.new()
	fx.name = "BlindingEclipse"
	get_parent().add_child(fx)

	var dome := _make_circle(fx, 80.0, 48, Color(0.025, 0.02, 0.08, 0.82), Color(0.45, 0.35, 0.75, 0.9))
	var rim := _make_circle(fx, 80.0, 48, Color(0.0, 0.0, 0.0, 0.0), Color(0.85, 0.65, 1.0, 0.8))

	var t := 0.0
	var fire_timer := 0.0
	while t < 4.0 and is_instance_valid(self) and not is_dead:
		var delta := get_physics_process_delta_time()
		t += delta
		fire_timer -= delta
		var radius := lerp(80.0, 300.0, min(t / 1.1, 1.0))
		dome.scale = Vector2.ONE * (radius / 80.0)
		rim.scale = Vector2.ONE * (radius / 80.0)

		if player_ref and is_instance_valid(player_ref):
			if player_ref.global_position.distance_to(global_position) < radius:
				if player_ref.has_method("apply_boss_slow"):
					player_ref.apply_boss_slow(0.15, 0.48)
			elif fire_timer <= 0.0:
				fire_timer = 0.42
				var base := randf_range(0.0, TAU)
				for i in range(6):
					var a := base + TAU * float(i) / 6.0
					fire_projectile(Vector2(cos(a), sin(a)), 9.0 * difficulty_scale, 430.0)

		await get_tree().physics_frame

	if is_instance_valid(fx):
		fx.queue_free()
	is_busy = false

# --------------------------------------------------------------- ATTACK 5
## Three expanding shockwave rings; the player can avoid them with the dash's
## built-in invulnerability window.
func supernova_pulsar() -> void:
	set_next_attack_delay(2.4)
	is_busy = true
	_add_heat(25.0)

	for pulse in range(3):
		var fx := Node2D.new()
		fx.name = "SupernovaPulse%d" % (pulse + 1)
		get_parent().add_child(fx)

		var ring := _make_circle(fx, 18.0, 64, Color(1.0, 0.45, 0.08, 0.12), Color(1.0, 0.9, 0.35, 1.0))
		var t := 0.0
		while t < 1.0 and is_instance_valid(self) and not is_dead:
			var delta := get_physics_process_delta_time()
			t += delta
			var radius := lerp(18.0, arena_radius + 40.0, t)
			ring.scale = Vector2.ONE * (radius / 18.0)
			if player_ref and is_instance_valid(player_ref):
				var dist := player_ref.global_position.distance_to(global_position)
				if abs(dist - radius) < 24.0:
					_damage_player(28.0)
			await get_tree().physics_frame

		if is_instance_valid(fx):
			fx.queue_free()
		await get_tree().create_timer(0.22).timeout

	is_busy = false

func enrage() -> void:
	move_speed += 18.0
	heat_buildup = 100.0
