extends BossBase
class_name Chronokeeper

const CYAN := Color(0.25, 0.95, 1.0, 1.0)
const GOLD := Color(1.0, 0.78, 0.25, 1.0)
const RED := Color(1.0, 0.2, 0.3, 1.0)
const VIOLET := Color(0.75, 0.35, 1.0, 1.0)

var entropy_clock := 0.0
var entropy_paused := 0.0
var visual_time := 0.0
var telegraph_text := "ENTROPY HUM — HIT THE GLOWING GEARS"
var telegraph_color := CYAN
var telegraph_points: Array[Vector2] = []
var rhythm_tick := true
var beam_active := false

func _ready() -> void:
	boss_display_name = "The Chronokeeper"
	max_health = 340.0
	move_speed = 0.0
	attack_pattern = ["time_dilation", "rewind_mark", "tick_tock_rhythm", "paradox_beam"]
	super._ready()
	# Keep the boss above the floor/background so its custom-drawn art is visible.
	z_index = 5
	queue_redraw()

func _process(delta: float) -> void:
	if is_dead:
		return
	visual_time += delta
	entropy_clock += delta
	if entropy_paused > 0.0:
		entropy_paused = maxf(0.0, entropy_paused - delta)
	elif entropy_clock >= 5.0:
		entropy_clock = 0.0
		if player_ref and player_ref.has_method("take_damage"):
			player_ref.take_damage(1.0 * difficulty_scale, self)
	if entropy_paused <= 0.0:
		if fmod(visual_time, 4.0) < 1.0:
			telegraph_color = GOLD
			telegraph_text = "GEARS EXPOSED — HIT TO PAUSE ENTROPY"
		else:
			telegraph_color = CYAN
			telegraph_text = "ENTROPY HUM — EVERY 5 SECONDS"
	queue_redraw()

func _draw() -> void:
	# High-contrast clock face with a pulsing outer ring and clearly visible gears.
	var pulse := 1.0 + 0.035 * sin(visual_time * 3.0)
	draw_circle(Vector2.ZERO, 82.0 * pulse, Color(0.025, 0.045, 0.09, 0.98))
	draw_arc(Vector2.ZERO, 96.0 * pulse, 0.0, TAU, 72, CYAN, 5.0, true)
	draw_arc(Vector2.ZERO, 77.0, 0.0, TAU, 64, GOLD, 3.0, true)
	for i in range(12):
		var a := TAU * float(i) / 12.0
		var inner := Vector2(cos(a), sin(a)) * 65.0
		var outer := Vector2(cos(a), sin(a)) * 82.0
		draw_line(inner, outer, GOLD, 4.0)
	# Rotating clock hands.
	var hand_a := visual_time * 0.8
	var hand_b := -visual_time * 1.7
	draw_line(Vector2.ZERO, Vector2(cos(hand_a), sin(hand_a)) * 43.0, Color.WHITE, 5.0)
	draw_line(Vector2.ZERO, Vector2(cos(hand_b), sin(hand_b)) * 29.0, CYAN, 4.0)
	draw_circle(Vector2.ZERO, 7.0, GOLD)
	# Three bright weak-point gears.
	var gear_col := GOLD if entropy_paused <= 0.0 else CYAN
	for gear_pos in [Vector2(-48, -20), Vector2(48, -20), Vector2(0, 49)]:
		draw_circle(gear_pos, 17.0, Color(0.08, 0.12, 0.2, 1.0))
		draw_arc(gear_pos, 15.0, 0.0, TAU, 24, gear_col, 4.0, true)
		for tooth in range(8):
			var ta := TAU * float(tooth) / 8.0 + visual_time * 0.7
			draw_line(gear_pos + Vector2(cos(ta), sin(ta)) * 11.0, gear_pos + Vector2(cos(ta), sin(ta)) * 19.0, gear_col, 3.0)
		draw_circle(gear_pos, 4.0, Color.WHITE)
	for p in telegraph_points:
		var local_p := to_local(p)
		if beam_active:
			draw_line(Vector2.ZERO, local_p, RED, 7.0)
			draw_line(Vector2.ZERO, local_p, Color(1.0, 0.75, 0.75, 0.8), 2.0)
		draw_circle(local_p, 38.0, Color(RED.r, RED.g, RED.b, 0.14))
		draw_arc(local_p, 38.0, 0.0, TAU, 40, RED, 4.0, true)
		draw_arc(local_p, 48.0, visual_time, visual_time + PI * 1.4, 40, GOLD, 2.0, true)
	if telegraph_text != "":
		draw_string(ThemeDB.fallback_font, Vector2(-230, 133), telegraph_text, HORIZONTAL_ALIGNMENT_CENTER, 460, 17, telegraph_color)

func take_damage(amount: float, source: Node = null, is_dot: bool = false) -> void:
	if source != null and source.is_in_group("player"):
		entropy_paused = 2.0
		telegraph_text = "ENTROPY PAUSED — 2 SECONDS"
		telegraph_color = GOLD
		queue_redraw()
	super.take_damage(amount, source, is_dot)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_handle_burn(delta)
	if not has_enraged and current_health <= max_health * 0.5:
		has_enraged = true
		enrage()
	attack_timer -= delta
	if attack_timer <= 0.0 and not is_busy:
		_run_next_attack()
	velocity = Vector2.ZERO

func time_dilation() -> void:
	set_next_attack_delay(6.0)
	telegraph_text = "TIME DILATION — SLOWED 50%"
	telegraph_color = VIOLET
	telegraph_points.clear()
	if player_ref and player_ref.has_method("apply_boss_slow"):
		player_ref.apply_boss_slow(2.5, 0.5)
	for i in range(4):
		if is_dead:
			return
		if player_ref and player_ref.has_method("take_damage"):
			player_ref.take_damage(1.0 * difficulty_scale, self)
		await get_tree().create_timer(0.65).timeout
	telegraph_text = "ENTROPY HUM — EVERY 5 SECONDS"
	telegraph_color = CYAN

func rewind_mark() -> void:
	set_next_attack_delay(6.0)
	if not player_ref:
		return
	var marked_position := player_pos()
	telegraph_points = [marked_position]
	telegraph_color = RED
	for n in range(3, 0, -1):
		telegraph_text = "REWIND MARK — DASH AT ZERO: %d" % n
		queue_redraw()
		await get_tree().create_timer(1.0).timeout
	if is_dead or not is_instance_valid(self):
		return
	telegraph_points.clear()
	if player_ref:
		player_ref.global_position = marked_position
	if player_ref and player_ref.get("is_dashing") == true:
		telegraph_text = "REWIND DODGED!"
		telegraph_color = CYAN
	else:
		if player_ref and player_ref.has_method("take_damage"):
			player_ref.take_damage(12.0 * difficulty_scale, self)
		telegraph_text = "REWIND IMPACT — 12 DAMAGE"
	telegraph_points = [marked_position]
	await get_tree().create_timer(0.5).timeout
	telegraph_points.clear()
	telegraph_text = "ENTROPY HUM — EVERY 5 SECONDS"

func tick_tock_rhythm() -> void:
	set_next_attack_delay(6.5)
	telegraph_points.clear()
	for beat in range(6):
		rhythm_tick = beat % 2 == 0
		telegraph_text = "TICK — STAND STILL" if rhythm_tick else "TOCK — MOVE / JUMP / DASH"
		telegraph_color = CYAN if rhythm_tick else GOLD
		queue_redraw()
		var start := player_pos()
		await get_tree().create_timer(0.75).timeout
		if not is_dead and player_ref and player_ref.has_method("take_damage"):
			var moved := player_pos().distance_to(start) > 12.0
			if (rhythm_tick and moved) or (not rhythm_tick and not moved):
				player_ref.take_damage(3.0 * difficulty_scale, self)
	telegraph_text = "ENTROPY HUM — EVERY 5 SECONDS"

func paradox_beam() -> void:
	set_next_attack_delay(5.5)
	if not player_ref:
		return
	telegraph_text = "PARADOX BEAM — MOVE OUT OF THE RED RING"
	telegraph_color = RED
	var predicted :Vector2= player_pos() + player_ref.velocity * 0.65
	telegraph_points = [predicted]
	beam_active = true
	queue_redraw()
	await get_tree().create_timer(1.25).timeout
	if is_dead or not is_instance_valid(self):
		return
	telegraph_text = "BEAM FIRED — CHANGE DIRECTION!"
	if player_ref and player_ref.global_position.distance_to(predicted) < 75.0 and player_ref.has_method("take_damage"):
		player_ref.take_damage(10.0 * difficulty_scale, self)
	telegraph_points.clear()
	beam_active = false
	await get_tree().create_timer(0.5).timeout
	telegraph_text = "ENTROPY HUM — EVERY 5 SECONDS"

func enrage() -> void:
	telegraph_text = "TEMPORAL COLLAPSE — FASTER RHYTHM"
	telegraph_color = RED
