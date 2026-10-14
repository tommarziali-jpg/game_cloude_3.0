extends BossBase
class_name Chronokeeper

const CYAN := Color(0.25, 0.95, 1.0, 1.0)
const GOLD := Color(1.0, 0.78, 0.25, 1.0)
const RED := Color(1.0, 0.2, 0.3, 1.0)
const VIOLET := Color(0.75, 0.35, 1.0, 1.0)

var entropy_clock := 0.0
var entropy_paused := 0.0
var telegraph_text := "EXPOSED GEARS: strike to pause Entropy"
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
	z_index = -1
	queue_redraw()

func _process(delta: float) -> void:
	if is_dead:
		return
	entropy_clock += delta
	if entropy_paused > 0.0:
		entropy_paused = maxf(0.0, entropy_paused - delta)
	elif entropy_clock >= 5.0:
		entropy_clock = 0.0
		if player_ref and player_ref.has_method("take_damage"):
			player_ref.take_damage(2.0 * difficulty_scale, self)
	if entropy_paused <= 0.0:
		# The gears are exposed briefly so a hit can silence the aura.
		if fmod(Time.get_ticks_msec() / 1000.0, 4.0) < 1.0:
			telegraph_color = GOLD
			telegraph_text = "GEARS EXPOSED — HIT THE CLOCKWORK!"
		else:
			telegraph_color = CYAN
			telegraph_text = "ENTROPY HUM — GEAR HITS PAUSE IT"
	queue_redraw()

func _draw() -> void:
	# Clockwork silhouette and three hittable-looking gear weak points.
	draw_circle(Vector2.ZERO, 82.0, Color(0.04, 0.08, 0.15, 0.88))
	draw_arc(Vector2.ZERO, 92.0, 0.0, TAU, 64, CYAN, 4.0, true)
	draw_arc(Vector2.ZERO, 72.0, 0.0, TAU, 48, GOLD, 3.0, true)
	for i in range(12):
		var a := TAU * float(i) / 12.0
		draw_line(Vector2(cos(a), sin(a)) * 62.0, Vector2(cos(a), sin(a)) * 78.0, GOLD, 4.0)
	draw_line(Vector2.ZERO, Vector2(0, -43), Color.WHITE, 5.0)
	draw_line(Vector2.ZERO, Vector2(31, 20), CYAN, 4.0)
	var gear_col := GOLD if entropy_paused <= 0.0 else CYAN
	draw_circle(Vector2(-48, -20), 13.0, gear_col)
	draw_circle(Vector2(48, -20), 13.0, gear_col)
	draw_circle(Vector2(0, 49), 13.0, gear_col)
	for p in telegraph_points:
		if beam_active:
			draw_line(Vector2.ZERO, to_local(p), RED, 6.0)
		draw_circle(to_local(p), 30.0, Color(RED.r, RED.g, RED.b, 0.18))
		draw_arc(to_local(p), 30.0, 0.0, TAU, 32, RED, 3.0, true)
	if telegraph_text != "":
		draw_string(ThemeDB.fallback_font, Vector2(-200, 120), telegraph_text, HORIZONTAL_ALIGNMENT_CENTER, 400, 17, telegraph_color)

func take_damage(amount: float, source: Node = null, is_dot: bool = false) -> void:
	if source != null and source.is_in_group("player"):
		entropy_paused = 2.0
		telegraph_text = "GEARS STRUCK — ENTROPY PAUSED 2s"
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
	set_next_attack_delay(5.0)
	telegraph_text = "TIME DILATION — SLOWED 50% + DAMAGE"
	telegraph_color = VIOLET
	telegraph_points.clear()
	if player_ref and player_ref.has_method("apply_boss_slow"):
		player_ref.apply_boss_slow(3.0, 0.5)
	for i in range(6):
		if is_dead: return
		if player_ref and player_ref.has_method("take_damage"):
			player_ref.take_damage(2.0 * difficulty_scale, self)
		await get_tree().create_timer(0.5).timeout
	telegraph_text = "ENTROPY HUM — GEAR HITS PAUSE IT"
	telegraph_color = CYAN

func rewind_mark() -> void:
	set_next_attack_delay(5.0)
	if not player_ref: return
	var marked_position := player_pos()
	telegraph_points = [marked_position]
	telegraph_color = RED
	for n in range(3, 0, -1):
		telegraph_text = "REWIND MARK — DASH AT ZERO: %d" % n
		queue_redraw()
		await get_tree().create_timer(1.0).timeout
	if is_dead or not is_instance_valid(self): return
	telegraph_points.clear()
	# Rewind teleports the player to the marked spot after the three-second cue.
	# Dash active at the impact beat is the intended timing window.
	if player_ref:
		player_ref.global_position = marked_position
	if player_ref and player_ref.get("is_dashing") == true:
		telegraph_text = "REWIND DODGED!"
		telegraph_color = CYAN
	else:
		if player_ref and player_ref.has_method("take_damage"):
			player_ref.take_damage(28.0 * difficulty_scale, self)
		telegraph_text = "REWIND IMPACT!"
	telegraph_points = [marked_position]
	await get_tree().create_timer(0.5).timeout
	telegraph_points.clear()
	telegraph_text = "ENTROPY HUM — GEAR HITS PAUSE IT"

func tick_tock_rhythm() -> void:
	set_next_attack_delay(6.0)
	telegraph_points.clear()
	for beat in range(6):
		rhythm_tick = beat % 2 == 0
		telegraph_text = "TICK — STAND STILL" if rhythm_tick else "TOCK — MOVE / JUMP / DASH"
		telegraph_color = CYAN if rhythm_tick else GOLD
		queue_redraw()
		var start := player_pos()
		await get_tree().create_timer(0.65).timeout
		if not is_dead and player_ref and player_ref.has_method("take_damage"):
			var moved := player_pos().distance_to(start) > 12.0
			if (rhythm_tick and moved) or (not rhythm_tick and not moved):
				player_ref.take_damage(7.0 * difficulty_scale, self)
	telegraph_text = "ENTROPY HUM — GEAR HITS PAUSE IT"

func paradox_beam() -> void:
	set_next_attack_delay(4.5)
	if not player_ref: return
	telegraph_text = "PARADOX BEAM — TARGET LOCK!"
	telegraph_color = RED
	var predicted := player_pos() + player_ref.velocity * 0.65
	telegraph_points = [predicted]
	beam_active = true
	queue_redraw()
	await get_tree().create_timer(1.0).timeout
	if is_dead or not is_instance_valid(self): return
	telegraph_text = "BEAM FIRED — CHANGE DIRECTION!"
	if player_ref and player_ref.global_position.distance_to(predicted) < 75.0 and player_ref.has_method("take_damage"):
		player_ref.take_damage(22.0 * difficulty_scale, self)
	telegraph_points.clear()
	beam_active = false
	await get_tree().create_timer(0.4).timeout
	telegraph_text = "ENTROPY HUM — GEAR HITS PAUSE IT"

func enrage() -> void:
	telegraph_text = "TEMPORAL COLLAPSE — FASTER RHYTHM"
	telegraph_color = RED
