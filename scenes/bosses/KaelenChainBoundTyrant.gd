extends BossBase
class_name KaelenChainBoundTyrant
## Boss #4 -- Floors 20, 120, 170... (Floor 70 is reserved for Sir Gideon.)
## VISUAL MAPPING
## - Body: ruined warden with four huge iron chains reaching toward the ceiling.
## - Pendulum Sweep: the body swings in a wide arc while chain tension is shown.
## - Vortex Slam: rotating chain motion around the boss marks the floor vortex.
## - Ceiling Anchor Drop: fading boss plus four floor markers show the anchors; the expanding ring marks the crash.
## - Iron Net Lasso: two wide chain lines visibly close together around the target.
## - Chain-Link Gridlock: multiple floor lines form the moving tripwire grid.

## The Chain-Bound Tyrant: Kaelen, The Anchor of Despair
## Replaces the Glass Tyrant boss slot. Theme: structural chains,
## vertical containment, and whiplash momentum.

var chain_points: Array[Vector2] = []
var chain_active: bool = false

func _ready() -> void:
	boss_display_name = "Kaelen, The Anchor of Despair"
	max_health = 300.0
	move_speed = 92.0
	attack_pattern = [
		"pendulum_sweep",
		"vortex_slam",
		"ceiling_anchor_drop",
		"iron_net_lasso",
		"chain_link_gridlock"
	]
	super._ready()
	_build_chain_points()
	queue_redraw()

func _build_chain_points() -> void:
	chain_points = [
		Vector2(-145, -120),
		Vector2(145, -120),
		Vector2(-145, 120),
		Vector2(145, 120)
	]

func _draw() -> void:
	# Four huge iron chains reaching into the tower's ceiling.
	var links: int = 10
	for anchor in chain_points:
		draw_line(anchor, anchor + Vector2(0, -430), Color(0.12, 0.13, 0.15, 0.95), 8.0)
		for i in range(links):
			var p := anchor + Vector2(0, -38 * float(i))
			draw_arc(p, 7.0, 0.0, TAU, 10, Color(0.42, 0.44, 0.47, 0.95), 3.0)
	# Anchor hubs.
	for anchor in chain_points:
		draw_circle(anchor, 12.0, Color(0.18, 0.19, 0.21, 1.0))
		draw_circle(anchor, 6.0, Color(0.48, 0.49, 0.5, 1.0))
	# Heavy boots.
	draw_rect(Rect2(-30, 22, 20, 16), Color(0.08, 0.09, 0.1, 1.0))
	draw_rect(Rect2(10, 22, 20, 16), Color(0.08, 0.09, 0.1, 1.0))

func _set_chain_tension(active: bool) -> void:
	chain_active = active
	queue_redraw()

# --------------------------------------------------------------- ATTACK 1
## Kaelen grabs a ceiling chain, swings in a huge arc, then rebounds away.
func pendulum_sweep() -> void:
	set_next_attack_delay(3.8)
	is_busy = true
	_set_chain_tension(true)
	var start: Vector2 = global_position
	var target: Vector2 = player_pos()
	var side: float = 1.0 if randf() > 0.5 else -1.0
	for i in range(18):
		var t := float(i + 1) / 18.0
		var angle := lerpf(-1.25, 1.25, t) * side
		var swing := Vector2(cos(angle) * 250.0, sin(angle) * 120.0)
		global_position = start + swing + (target - start) * t * 0.35
		if global_position.distance_to(player_pos()) < 48.0:
			_damage_player(18.0 * difficulty_scale)
		await get_tree().process_frame
	global_position = global_position.clamp(arena_center - Vector2(arena_radius, arena_radius), arena_center + Vector2(arena_radius, arena_radius))
	_set_chain_tension(false)
	is_busy = false

# --------------------------------------------------------------- ATTACK 2
## The chains coil around Kaelen as he becomes a fast ground-level vortex.
func vortex_slam() -> void:
	set_next_attack_delay(3.4)
	is_busy = true
	_set_chain_tension(true)
	var start := global_position
	var target := player_pos()
	for i in range(20):
		var t := float(i + 1) / 20.0
		var pos := start.lerp(target, t)
		var orbit := Vector2(cos(t * TAU * 2.5), sin(t * TAU * 2.5)) * 28.0
		global_position = pos + orbit
		queue_redraw()
		if global_position.distance_to(player_pos()) < 58.0:
			_damage_player(10.0 * difficulty_scale)
		await get_tree().process_frame
	_set_chain_tension(false)
	is_busy = false

# --------------------------------------------------------------- ATTACK 3
## Kaelen launches upward; four chain anchors slam down around the player's
## predicted position, followed by a vertical crash.
func ceiling_anchor_drop() -> void:
	set_next_attack_delay(4.2)
	is_busy = true
	_set_chain_tension(true)
	var target := player_pos()
	var start := global_position
	global_position = start + Vector2(0, -520)
	modulate.a = 0.25
	for i in range(4):
		var corner := target + Vector2(-70 if i % 2 == 0 else 70, -70 if i < 2 else 70)
		_spawn_anchor_marker(corner)
		await get_tree().create_timer(0.12).timeout
	await get_tree().create_timer(0.35).timeout
	global_position = target
	modulate.a = 1.0
	_spawn_impact_ring()
	if global_position.distance_to(player_pos()) < 72.0:
		_damage_player(28.0 * difficulty_scale)
	_set_chain_tension(false)
	is_busy = false

func _spawn_anchor_marker(pos: Vector2) -> void:
	var marker := Polygon2D.new()
	marker.color = Color(0.3, 0.32, 0.34, 0.9)
	marker.polygon = PackedVector2Array([Vector2(-14, -14), Vector2(14, -14), Vector2(14, 14), Vector2(-14, 14)])
	get_parent().add_child(marker)
	marker.global_position = pos
	var tween: Tween = create_tween()
	tween.tween_property(marker, "scale", Vector2(1.5, 1.5), 0.25)
	tween.tween_property(marker, "modulate:a", 0.0, 0.25)
	tween.tween_callback(marker.queue_free)

# --------------------------------------------------------------- ATTACK 4
## Two chains form a wide V and snap shut toward the player.
func iron_net_lasso() -> void:
	set_next_attack_delay(3.6)
	is_busy = true
	var target := player_pos()
	var left := target + Vector2(-260, -80)
	var right := target + Vector2(260, -80)
	for i in range(14):
		var t := float(i + 1) / 14.0
		var lp := global_position.lerp(left, t)
		var rp := global_position.lerp(right, t)
		_draw_temporary_chain(lp, rp)
		if _segment_distance(player_pos(), lp, target) < 32.0 or _segment_distance(player_pos(), rp, target) < 32.0:
			_damage_player(7.0 * difficulty_scale)
		await get_tree().process_frame
	for i in range(10):
		var t := float(i + 1) / 10.0
		var lp := left.lerp(target, t)
		var rp := right.lerp(target, t)
		_draw_temporary_chain(lp, rp)
		if player_pos().distance_to(target) < 60.0:
			_damage_player(5.0 * difficulty_scale)
		await get_tree().process_frame
	is_busy = false

func _draw_temporary_chain(a: Vector2, b: Vector2) -> void:
	var line := Line2D.new()
	line.width = 9.0
	line.default_color = Color(0.25, 0.27, 0.29, 0.9)
	line.points = PackedVector2Array([a, b])
	get_parent().add_child(line)
	var tween := create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.18)
	tween.tween_callback(line.queue_free)

# --------------------------------------------------------------- ATTACK 5
## Four chains latch to the walls while Kaelen drags a moving grid across
## the floor, creating visible high-tension tripwire lines.
func chain_link_gridlock() -> void:
	set_next_attack_delay(4.5)
	is_busy = true
	_set_chain_tension(true)
	var radius: float = arena_radius * 0.78
	for row in range(4):
		var y := lerpf(-radius, radius, float(row) / 3.0)
		var a := arena_center + Vector2(-radius, y)
		var b := arena_center + Vector2(radius, y)
		_draw_grid_line(a, b)
	for col in range(4):
		var x := lerpf(-radius, radius, float(col) / 3.0)
		var a := arena_center + Vector2(x, -radius)
		var b := arena_center + Vector2(x, radius)
		_draw_grid_line(a, b)
	for i in range(18):
		var perimeter := arena_center + Vector2(cos(float(i) * 0.55), sin(float(i) * 0.55)) * radius
		global_position = perimeter
		if global_position.distance_to(player_pos()) < 52.0:
			_damage_player(9.0 * difficulty_scale)
		await get_tree().process_frame
	_set_chain_tension(false)
	is_busy = false

func _draw_grid_line(a: Vector2, b: Vector2) -> void:
	var line := Line2D.new()
	line.width = 5.0
	line.default_color = Color(0.5, 0.52, 0.54, 0.75)
	line.points = PackedVector2Array([a, b])
	get_parent().add_child(line)
	var tween := create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 3.8)
	tween.tween_callback(line.queue_free)

func _segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var denom := ab.length_squared()
	if denom <= 0.001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / denom, 0.0, 1.0)
	return point.distance_to(a.lerp(b, t))

func _damage_player(amount: float) -> void:
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(amount, self)

func _spawn_impact_ring() -> void:
	var ring := Line2D.new()
	ring.width = 7.0
	ring.default_color = Color(0.65, 0.67, 0.7, 0.9)
	var pts := PackedVector2Array()
	for i in range(25):
		var a := TAU * float(i) / 24.0
		pts.append(Vector2(cos(a), sin(a)) * 20.0)
	ring.points = pts
	get_parent().add_child(ring)
	ring.global_position = global_position
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector2(4.0, 4.0), 0.35)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.35)
	tween.tween_callback(ring.queue_free)

func enrage() -> void:
	move_speed += 18.0
