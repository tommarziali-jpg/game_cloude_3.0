extends BossBase
class_name GrandmasterValerius

## Grandmaster Valerius, The Echoing Duelist.
## Boss #3 -- Floors 15, 65, 115...
## VISUAL MAPPING
## - Body: compact duelist silhouette with a readable blade-fighter profile.
## - Blink Strike Grid: pale path lines and afterimages mark the teleport grid.
## - Vaulting Descent: ground shadow, enlarged silhouette, then expanding ring show the leap and landing.
## - Cyclone Chase: rapid rotation is the spinning blade-vortex cue.
## - Echo Parry: faded blue glide means the defensive parry is active; smoke marks the counter.
## - Boundary Execution: four ghost copies and crossing lines show the simultaneous cross-slash.

## Grandmaster Valerius, The Echoing Duelist.

const BLINK_SPEED := 980.0
const CYCLONE_DURATION := 2.4
const PARRY_DURATION := 1.15
const ARENA_MARGIN := 0.82

var parry_active := false
var parry_triggered := false

func _ready() -> void:
	boss_display_name = "Grandmaster Valerius, The Echoing Duelist"
	max_health = 285.0
	move_speed = 128.0
	attack_pattern = ["blink_strike_grid", "vaulting_descent", "cyclone_chase", "echo_parry", "boundary_execution"]
	super._ready()

func enrage() -> void:
	move_speed += 28.0

func take_damage(amount: float, _source: Node = null, is_dot: bool = false) -> void:
	if parry_active and not parry_triggered and not is_dead:
		parry_triggered = true
		parry_active = false
		_execute_parry_counter()
		return
	super.take_damage(amount, _source, is_dot)

func blink_strike_grid() -> void:
	set_next_attack_delay(3.0)
	is_busy = true
	var path: Array[Vector2] = []
	var count := randi_range(3, 5)
	for i in range(count):
		var p := player_pos() + Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(90.0, 260.0)
		p = arena_center + (p - arena_center).limit_length(arena_radius * ARENA_MARGIN)
		path.append(p)
	var trail := Line2D.new()
	trail.width = 8.0
	trail.default_color = Color(0.65, 0.85, 1.0, 0.5)
	trail.points = PackedVector2Array([global_position] + path)
	get_tree().current_scene.add_child(trail)
	for p in path:
		global_position = p
		_spawn_afterimage(p)
		await get_tree().create_timer(0.16).timeout
	for p in path:
		var start := global_position
		var duration := maxf(0.08, start.distance_to(p) / BLINK_SPEED)
		var t := 0.0
		while t < duration and not is_dead:
			t += get_physics_process_delta_time()
			global_position = start.lerp(p, clampf(t / duration, 0.0, 1.0))
			if player_ref and player_pos().distance_to(global_position) < 48.0:
				player_ref.take_damage(18.0 * difficulty_scale, self)
			await get_tree().physics_frame
	if is_instance_valid(trail):
		trail.queue_free()
	is_busy = false

func vaulting_descent() -> void:
	set_next_attack_delay(3.2)
	is_busy = true
	var wall := arena_center + (player_pos() - arena_center).normalized() * arena_radius * 0.78
	_spawn_ground_shadow(wall)
	await get_tree().create_timer(0.45).timeout
	global_position = wall
	if visual: visual.scale = Vector2(1.65, 1.65)
	await get_tree().create_timer(0.5).timeout
	var landing := arena_center + (player_pos() - arena_center).limit_length(arena_radius * ARENA_MARGIN)
	global_position = landing
	if visual: visual.scale = Vector2.ONE
	await _spawn_shockwave(landing, arena_radius * 0.68, 0.65, 20.0 * difficulty_scale)
	is_busy = false

func cyclone_chase() -> void:
	set_next_attack_delay(3.4)
	is_busy = true
	var elapsed := 0.0
	while elapsed < CYCLONE_DURATION and not is_dead:
		var delta := get_physics_process_delta_time()
		elapsed += delta
		global_position += (player_pos() - global_position).normalized() * move_speed * 1.12 * delta
		global_position = arena_center + (global_position - arena_center).limit_length(arena_radius * ARENA_MARGIN)
		rotation += delta * 10.0
		if player_ref and player_pos().distance_to(global_position) < 52.0:
			player_ref.take_damage(7.0 * difficulty_scale * delta * 5.0, self)
		await get_tree().physics_frame
	rotation = 0.0
	is_busy = false

func echo_parry() -> void:
	set_next_attack_delay(3.8)
	parry_active = true
	parry_triggered = false
	is_busy = true
	if visual: visual.modulate = Color(0.7, 0.9, 1.0, 0.55)
	var start := global_position
	var target := arena_center + Vector2.from_angle(randf_range(0.0, TAU)) * arena_radius * 0.55
	var t := 0.0
	while t < PARRY_DURATION and not parry_triggered and not is_dead:
		t += get_physics_process_delta_time()
		global_position = start.lerp(target, clampf(t / PARRY_DURATION, 0.0, 1.0))
		await get_tree().physics_frame
	parry_active = false
	if visual: visual.modulate = Color.WHITE
	is_busy = false

func _execute_parry_counter() -> void:
	is_busy = true
	_spawn_smoke(global_position)
	var target := player_pos()
	var facing := Vector2.DOWN
	if player_ref:
		var f = player_ref.get("facing")
		if f is Vector2 and f.length() > 0.1: facing = f.normalized()
	await get_tree().create_timer(0.16).timeout
	global_position = arena_center + (target + facing * 62.0 - arena_center).limit_length(arena_radius * ARENA_MARGIN)
	_spawn_afterimage(global_position)
	if player_ref and player_pos().distance_to(global_position) < 92.0:
		player_ref.take_damage(30.0 * difficulty_scale, self)
	await get_tree().create_timer(0.22).timeout
	is_busy = false

func boundary_execution() -> void:
	set_next_attack_delay(4.6)
	is_busy = true
	global_position = arena_center
	var d := arena_radius * 0.78
	var corners := [arena_center + Vector2(-d,-d), arena_center + Vector2(d,-d), arena_center + Vector2(d,d), arena_center + Vector2(-d,d)]
	var clones: Array[Node2D] = []
	for p in corners: clones.append(_ghost(p))
	var lines: Array[Line2D] = []
	for pts in [[Vector2(-1,-1),Vector2(1,1)],[Vector2(1,-1),Vector2(-1,1)]]:
		var line := Line2D.new()
		line.width = 14.0
		line.default_color = Color(0.72, 0.9, 1.0, 0.3)
		line.points = PackedVector2Array([arena_center + pts[0] * arena_radius * 1.1, arena_center + pts[1] * arena_radius * 1.1])
		get_tree().current_scene.add_child(line)
		lines.append(line)
	await get_tree().create_timer(0.9).timeout
	var t := 0.0
	var hit := false
	while t < 0.4 and not is_dead:
		t += get_physics_process_delta_time()
		if player_ref and not hit:
			var p := player_pos()
			if minf(_segment_distance(p, arena_center - Vector2.ONE * arena_radius * 1.1, arena_center + Vector2.ONE * arena_radius * 1.1), _segment_distance(p, arena_center - Vector2(arena_radius,-arena_radius) * 1.1, arena_center + Vector2(arena_radius,-arena_radius) * 1.1)) < 34.0:
				player_ref.take_damage(34.0 * difficulty_scale, self)
				hit = true
		await get_tree().physics_frame
	for n in clones:
		if is_instance_valid(n): n.queue_free()
	for n in lines:
		if is_instance_valid(n): n.queue_free()
	is_busy = false

func _spawn_afterimage(pos: Vector2) -> void:
	var g := Polygon2D.new()
	g.polygon = PackedVector2Array([Vector2(0,-30),Vector2(18,-8),Vector2(12,28),Vector2(-12,28),Vector2(-18,-8)])
	g.color = Color(0.55,0.8,1.0,0.3)
	g.global_position = pos
	get_tree().current_scene.add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.35)
	tw.tween_callback(g.queue_free)

func _ghost(pos: Vector2) -> Node2D:
	var g := Node2D.new()
	g.global_position = pos
	var b := Polygon2D.new()
	b.polygon = PackedVector2Array([Vector2(0,-34),Vector2(22,-10),Vector2(16,30),Vector2(-16,30),Vector2(-22,-10)])
	b.color = Color(0.58,0.82,1.0,0.48)
	g.add_child(b)
	get_tree().current_scene.add_child(g)
	return g

func _spawn_ground_shadow(pos: Vector2) -> void:
	var s := Polygon2D.new()
	s.polygon = PackedVector2Array([Vector2(-30,-12),Vector2(30,-12),Vector2(40,12),Vector2(-40,12)])
	s.color = Color(0.05,0.08,0.12,0.55)
	s.global_position = pos
	get_tree().current_scene.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector2(2.8,2.8), 0.85)
	tw.tween_property(s, "modulate:a", 0.0, 0.2)
	tw.tween_callback(s.queue_free)

func _spawn_smoke(pos: Vector2) -> void:
	var s := Polygon2D.new()
	s.polygon = PackedVector2Array([Vector2(-28,0),Vector2(-10,-24),Vector2(18,-22),Vector2(32,0),Vector2(14,24),Vector2(-18,20)])
	s.color = Color(0.25,0.3,0.38,0.72)
	s.global_position = pos
	get_tree().current_scene.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector2(1.8,1.8), 0.28)
	tw.tween_property(s, "modulate:a", 0.0, 0.25)
	tw.tween_callback(s.queue_free)

func _spawn_shockwave(center: Vector2, max_radius: float, duration: float, damage: float) -> void:
	var ring := Line2D.new()
	ring.width = 10.0
	ring.default_color = Color(0.6,0.85,1.0,0.88)
	var pts := PackedVector2Array()
	for i in range(49):
		var a := TAU * float(i) / 48.0
		pts.append(Vector2(cos(a),sin(a)))
	ring.points = pts
	ring.global_position = center
	ring.scale = Vector2.ONE * 0.05
	get_tree().current_scene.add_child(ring)
	var t := 0.0
	var previous := max_radius * 0.05
	var hit := false
	while t < duration and is_instance_valid(ring):
		t += get_physics_process_delta_time()
		var radius := lerpf(max_radius * 0.05,max_radius,clampf(t/duration,0.0,1.0))
		ring.scale = Vector2.ONE * radius
		if not hit and player_ref and player_pos().distance_to(center) >= previous and player_pos().distance_to(center) <= radius:
			player_ref.take_damage(damage,self)
			hit = true
		previous = radius
		await get_tree().physics_frame
	if is_instance_valid(ring): ring.queue_free()

func _segment_distance(p: Vector2,a: Vector2,b: Vector2) -> float:
	var ab := b-a
	var len2 := ab.length_squared()
	if len2 <= 0.001: return p.distance_to(a)
	return p.distance_to(a + ab * clampf((p-a).dot(ab)/len2,0.0,1.0))
