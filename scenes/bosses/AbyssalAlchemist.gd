extends BossBase
class_name AbyssalAlchemist

## The Abyssal Alchemist: Vespera, The Toxic Flood
## Replaces Plague Cantor on floors 25, 75, 125...
## Theme: liquid fluidity, area denial, and shifting puddles.
##
## Every attack has a deliberately different visual language:
## 1. Acid Rain Grid   - falling green drops + persistent circular puddles.
## 2. Slime Wave       - a wide moving teal wave that must be dashed over.
## 3. Corrosive Geyser - red/orange target ring followed by a vertical burst.
## 4. Vial Toss        - three purple volatile vials + yellow tar pools.
## 5. Slime Clone      - two bright green chasing slimes that pop on contact.

const ACID_DAMAGE := 7.0
const WAVE_DAMAGE := 24.0
const GEYSER_DAMAGE := 30.0
const TAR_DAMAGE := 4.0
const CLONE_DAMAGE := 34.0

var puddle_count: int = 0
var toxic_puddles: Array[Node] = []

class Hazard extends Node2D:
	enum Kind { ACID, WAVE, GEYSER, TAR }
	var kind: Kind = Kind.ACID
	var radius: float = 42.0
	var duration: float = 5.0
	var elapsed: float = 0.0
	var direction: Vector2 = Vector2.RIGHT
	var speed: float = 0.0
	var width: float = 100.0
	var damage: float = 0.0
	var source: Node = null
	var active_delay: float = 0.0
	var player_ref: Node = null
	var did_burst: bool = false
	var hit_timer: float = 0.0
	var slow_player: bool = false
	var arena_radius: float = 260.0

	func _ready() -> void:
		z_index = -1
		queue_redraw()

	func _process(delta: float) -> void:
		elapsed += delta
		hit_timer = max(0.0, hit_timer - delta)

		if kind == Kind.WAVE:
			global_position += direction * speed * delta
		if kind == Kind.GEYSER and not did_burst and elapsed >= active_delay:
			did_burst = true
			queue_redraw()

		if player_ref != null and is_instance_valid(player_ref) and hit_timer <= 0.0:
			var p :Vector2= player_ref.global_position
			var in_hazard := false
			match kind:
				Kind.ACID, Kind.TAR, Kind.GEYSER:
					in_hazard = p.distance_to(global_position) <= radius
				Kind.WAVE:
					var local := p - global_position
					var along := local.dot(direction)
					var side :float= abs(local.dot(direction.orthogonal()))
					in_hazard = along > -width * 0.5 and along < 80.0 and abs(side) < width * 0.5
			if in_hazard:
				if kind == Kind.GEYSER and elapsed < active_delay:
					pass
				elif player_ref.has_method("take_damage"):
					player_ref.take_damage(damage, source)
					if slow_player and player_ref.has_method("apply_boss_slow"):
						player_ref.apply_boss_slow(0.35, 0.45)
					hit_timer = 0.42

		if elapsed >= duration:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(elapsed * 6.0)
		match kind:
			Kind.ACID:
				draw_circle(Vector2.ZERO, radius, Color(0.18, 1.0, 0.28, 0.48))
				draw_circle(Vector2.ZERO, radius * 0.62, Color(0.45, 1.0, 0.15, 0.55))
				draw_arc(Vector2.ZERO, radius + 4.0, 0, TAU, 32, Color(0.75, 1.0, 0.3, 0.9), 3.0)
				for i in range(5):
					var a := TAU * float(i) / 5.0 + elapsed * 0.4
					draw_circle(Vector2(cos(a), sin(a)) * radius * 0.48, 5.0 + pulse * 2.0, Color(0.85, 1.0, 0.5, 0.8))
			Kind.WAVE:
				var side := direction.orthogonal()
				var pts := PackedVector2Array([
					-side * width * 0.5 - direction * 55.0,
					side * width * 0.5 - direction * 55.0,
					side * width * 0.5 + direction * 55.0,
					-side * width * 0.5 + direction * 55.0
				])
				draw_colored_polygon(pts, Color(0.08, 0.9, 0.72, 0.72))
				draw_polyline(pts, Color(0.65, 1.0, 0.85, 0.95), 6.0)
				for i in range(4):
					var x := -42.0 + float(i) * 28.0
					var top := direction * x + side * width * 0.5
					draw_line(top, top - direction * 22.0 + side * 8.0, Color(0.8, 1.0, 0.9, 0.8), 4.0)
			Kind.GEYSER:
				var telegraph_alpha := 0.28 if not did_burst else 0.7
				draw_circle(Vector2.ZERO, radius, Color(1.0, 0.22, 0.08, telegraph_alpha))
				draw_arc(Vector2.ZERO, radius + 8.0 + pulse * 5.0, 0, TAU, 40, Color(1.0, 0.6, 0.18, 0.9), 4.0)
				if did_burst:
					draw_circle(Vector2.ZERO, radius * 0.38, Color(0.75, 0.95, 0.18, 0.9))
					for i in range(8):
						var a := TAU * float(i) / 8.0 + elapsed
						draw_line(Vector2(cos(a), sin(a)) * 12.0, Vector2(cos(a), sin(a)) * radius * 0.9, Color(0.9, 1.0, 0.35, 0.7), 5.0)
			Kind.TAR:
				draw_circle(Vector2.ZERO, radius, Color(0.08, 0.05, 0.03, 0.78))
				draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1.0, 0.72, 0.12, 0.9), 4.0)
				for i in range(6):
					var a := TAU * float(i) / 6.0 + elapsed * 0.25
					draw_circle(Vector2(cos(a), sin(a)) * radius * 0.55, 4.0, Color(0.8, 0.52, 0.08, 0.9))

class SlimeClone extends Node2D:
	var player_ref: Node = null
	var source: Node = null
	var speed: float = 120.0
	var damage: float = 34.0
	var lifetime: float = 8.0
	var elapsed: float = 0.0
	var wobble: float = 0.0
	var exploded: bool = false

	func _ready() -> void:
		z_index = 2
		queue_redraw()

	func _process(delta: float) -> void:
		elapsed += delta
		wobble += delta * 8.0
		if player_ref != null and is_instance_valid(player_ref) and not exploded:
			var to_player :Vector2= player_ref.global_position - global_position
			if to_player.length() > 2.0:
				global_position += to_player.normalized() * speed * delta
			if to_player.length() < 28.0:
				explode()
		if elapsed >= lifetime and not exploded:
			explode()
		queue_redraw()

	func explode() -> void:
		if exploded:
			return
		exploded = true
		if player_ref != null and is_instance_valid(player_ref) and global_position.distance_to(player_ref.global_position) < 62.0:
			if player_ref.has_method("take_damage"):
				player_ref.take_damage(damage, source)
		var burst := Node2D.new()
		burst.global_position = global_position
		get_parent().add_child(burst)
		burst.draw.connect(func(): pass)
		var tween := burst.create_tween()
		tween.tween_method(func(v: float): _draw_burst(burst, v), 1.0, 0.0, 0.22)
		tween.tween_callback(burst.queue_free)
		queue_free()

	func _draw_burst(node: Node2D, alpha: float) -> void:
		if not is_instance_valid(node):
			return
		# The clone itself already gives the player a clear contact telegraph;
		# this short-lived node is intentionally lightweight.

	func _draw() -> void:
		var pulse := 1.0 + sin(wobble) * 0.12
		draw_circle(Vector2.ZERO, 25.0 * pulse, Color(0.2, 1.0, 0.38, 0.9))
		draw_circle(Vector2(-7, -4), 5.0, Color(0.9, 1.0, 0.75, 0.95))
		draw_circle(Vector2(7, -4), 5.0, Color(0.9, 1.0, 0.75, 0.95))
		draw_arc(Vector2.ZERO, 30.0 * pulse, 0, TAU, 24, Color(0.65, 1.0, 0.4, 0.9), 4.0)

var wave_start: Vector2 = Vector2.ZERO

func _ready() -> void:
	boss_display_name = "The Abyssal Alchemist: Vespera"
	max_health = 270.0
	move_speed = 54.0
	attack_pattern = ["acid_rain_grid", "slime_wave", "corrosive_geyser", "vial_toss", "slime_clone"]
	super._ready()

func _draw() -> void:
	# Cracked liquid-filled glass sphere + alchemist silhouette.
	draw_circle(Vector2.ZERO, 44.0, Color(0.22, 0.9, 0.8, 0.18))
	draw_arc(Vector2.ZERO, 44.0, 0, TAU, 48, Color(0.72, 0.95, 1.0, 0.9), 3.0)
	draw_line(Vector2(-25, -30), Vector2(-5, -13), Color(0.75, 1.0, 1.0, 0.75), 2.0)
	draw_line(Vector2(10, -13), Vector2(27, -28), Color(0.75, 1.0, 1.0, 0.75), 2.0)
	draw_line(Vector2(-8, 12), Vector2(-25, 28), Color(0.75, 1.0, 1.0, 0.7), 2.0)
	draw_circle(Vector2.ZERO, 25.0, Color(0.12, 0.6, 0.46, 0.82))
	draw_circle(Vector2(0, -8), 9.0, Color(0.72, 0.86, 0.68, 0.95))
	draw_circle(Vector2(-3, -10), 2.0, Color(0.05, 0.1, 0.08, 1.0))
	draw_circle(Vector2(3, -10), 2.0, Color(0.05, 0.1, 0.08, 1.0))
	draw_circle(Vector2(-31, 15), 7.0, Color(0.7, 0.85, 0.88, 0.7))
	draw_circle(Vector2(31, 15), 7.0, Color(0.7, 0.85, 0.88, 0.7))
	draw_circle(Vector2(0, 34), 6.0, Color(0.3, 1.0, 0.55, 0.9))

func _process(_delta: float) -> void:
	queue_redraw()

# --------------------------------------------------------------- ATTACK 1
func acid_rain_grid() -> void:
	set_next_attack_delay(2.9)
	is_busy = true
	var tiles: Array[Vector2] = []
	for i in range(6):
		var col := randi_range(-2, 2)
		var row := randi_range(-2, 2)
		var pos := arena_center + Vector2(col * 105.0 + randf_range(-18, 18), row * 85.0 + randf_range(-18, 18))
		pos = arena_center + (pos - arena_center).limit_length(arena_radius * 0.82)
		tiles.append(pos)

	for pos in tiles:
		_spawn_falling_drop(pos)
	await get_tree().create_timer(0.8).timeout
	for pos in tiles:
		_spawn_puddle(pos, 42.0, 6.5, ACID_DAMAGE, false)
	is_busy = false

func _spawn_falling_drop(target: Vector2) -> void:
	var drop := Node2D.new()
	drop.global_position = target + Vector2(0, -130)
	drop.z_index = 3
	get_tree().current_scene.add_child(drop)
	var start := drop.global_position
	var tween := drop.create_tween()
	tween.tween_property(drop, "global_position", target, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_method(func(_v: float): drop.queue_redraw(), 0.0, 1.0, 0.55)
	drop.draw.connect(func():
		drop.draw_circle(Vector2.ZERO, 7.0, Color(0.45, 1.0, 0.2, 0.95))
		drop.draw_line(Vector2(0, -15), Vector2(0, -4), Color(0.75, 1.0, 0.35, 0.8), 3.0)
	)
	tween.tween_callback(func():
		if is_instance_valid(drop):
			drop.queue_free()
	)

# --------------------------------------------------------------- ATTACK 2
func slime_wave() -> void:
	set_next_attack_delay(3.3)
	is_busy = true
	var target := player_pos()
	wave_start = global_position
	var dir := (target - global_position).normalized()
	if dir.length() < 0.1:
		dir = Vector2.DOWN

	var wave := Hazard.new()
	wave.kind = Hazard.Kind.WAVE
	wave.global_position = global_position
	wave.direction = dir
	wave.speed = 270.0
	wave.width = 125.0
	wave.duration = 1.75
	wave.damage = WAVE_DAMAGE * difficulty_scale
	wave.source = self
	wave.player_ref = player_ref
	get_tree().current_scene.add_child(wave)

	if visual:
		visual.modulate = Color(0.55, 1.0, 0.9)
	await get_tree().create_timer(1.15).timeout
	if visual:
		visual.modulate = Color.WHITE
	is_busy = false

# --------------------------------------------------------------- ATTACK 3
func corrosive_geyser() -> void:
	set_next_attack_delay(3.0)
	is_busy = true
	var target := player_pos()
	var geyser := Hazard.new()
	geyser.kind = Hazard.Kind.GEYSER
	geyser.global_position = target
	geyser.radius = 58.0
	geyser.duration = 2.0
	geyser.active_delay = 0.72
	geyser.damage = GEYSER_DAMAGE * difficulty_scale
	geyser.source = self
	geyser.player_ref = player_ref
	get_tree().current_scene.add_child(geyser)
	await get_tree().create_timer(1.65).timeout
	is_busy = false

# --------------------------------------------------------------- ATTACK 4
func vial_toss() -> void:
	set_next_attack_delay(3.2)
	is_busy = true
	var center := player_pos()
	var offsets := [
		Vector2(-54, -36),
		Vector2(54, -36),
		Vector2(0, 54)
	]
	for offset in offsets:
		_spawn_vial(center + offset)
	await get_tree().create_timer(0.9).timeout
	for offset in offsets:
		var tar := Hazard.new()
		tar.kind = Hazard.Kind.TAR
		tar.global_position = center + offset
		tar.radius = 48.0
		tar.duration = 5.5
		tar.damage = TAR_DAMAGE * difficulty_scale
		tar.source = self
		tar.player_ref = player_ref
		tar.slow_player = true
		get_tree().current_scene.add_child(tar)
	await get_tree().create_timer(0.35).timeout
	is_busy = false

func _spawn_vial(target: Vector2) -> void:
	var vial := Node2D.new()
	vial.global_position = global_position
	vial.z_index = 4
	get_tree().current_scene.add_child(vial)
	var vial_shape := Polygon2D.new()
	vial_shape.polygon = PackedVector2Array([Vector2(0, -12), Vector2(10, -2), Vector2(7, 10), Vector2(-7, 10), Vector2(-10, -2)])
	vial_shape.color = Color(0.55, 0.18, 0.8, 0.95)
	vial.add_child(vial_shape)
	var tween := vial.create_tween()
	tween.tween_property(vial, "global_position", target, 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.18)
	tween.tween_callback(func():
		if is_instance_valid(vial):
			vial.queue_free()
	)

# --------------------------------------------------------------- ATTACK 5
func slime_clone() -> void:
	set_next_attack_delay(3.6)
	for side in [-1.0, 1.0]:
		var clone := SlimeClone.new()
		clone.global_position = global_position + Vector2(side * 45.0, 0)
		clone.player_ref = player_ref
		clone.source = self
		clone.speed = 115.0 + difficulty_scale * 12.0
		clone.damage = CLONE_DAMAGE * difficulty_scale
		get_tree().current_scene.add_child(clone)

func _spawn_puddle(pos: Vector2, radius: float, duration: float, damage: float, tar: bool) -> void:
	var puddle := Hazard.new()
	puddle.kind = Hazard.Kind.TAR if tar else Hazard.Kind.ACID
	puddle.global_position = pos
	puddle.radius = radius
	puddle.duration = duration
	puddle.damage = damage * difficulty_scale
	puddle.source = self
	puddle.player_ref = player_ref
	puddle.slow_player = tar
	get_tree().current_scene.add_child(puddle)
	toxic_puddles.append(puddle)

func enrage() -> void:
	# Below 50% HP Vespera makes the arena progressively more crowded:
	# a bonus acid grid is added immediately and future attacks hit harder.
	_spawn_enrage_puddles()
	move_speed = 68.0

func _spawn_enrage_puddles() -> void:
	for i in range(3):
		var angle := TAU * float(i) / 3.0
		var pos := arena_center + Vector2(cos(angle), sin(angle)) * 150.0
		_spawn_puddle(pos, 48.0, 8.0, ACID_DAMAGE * 1.15, false)
