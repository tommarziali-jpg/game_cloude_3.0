extends CharacterBody2D
class_name Player

## Top-down player controller: mouse-look aiming plus facing-relative WASD
## movement (twin-stick style) -- facing continuously tracks the mouse
## cursor, and W always moves forward toward it / S backs away from it /
## A and D strafe left and right relative to that facing direction, rather
## than moving in fixed absolute world directions. Dash with i-frames, a
## fixed Melee attack and a fixed Ranged attack (no more weapon loot --
## stats come from PlayerStats' aggregated Arcana Card / Artifact /
## Consumable effects), plus whichever single Active Major Arcana the
## player has equipped, bound to the Ability key. No block, no jump, per
## design spec.

signal died
signal attacked(kind: String)

const BASE_SPEED := 220.0
const DASH_SPEED := 720.0
const DASH_TIME := 0.16

const MELEE_DAMAGE := 9.0
const MELEE_RANGE := 58.0
const MELEE_ARC_DEG := 70.0
const MELEE_COOLDOWN := 0.55
const MELEE_KNOCKBACK := 90.0

const RANGED_DAMAGE := 7.0
const RANGED_RANGE := 420.0
const RANGED_COOLDOWN := 0.85
const RANGED_KNOCKBACK := 40.0
const RANGED_PROJECTILE_SPEED := 480.0

@onready var visual: Node2D = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sword_pivot: Node2D = $Visual/SwordPivot
@onready var attack_cd_melee: Timer = $MeleeCooldown
@onready var attack_cd_ranged: Timer = $RangedCooldown
@onready var dash_cd_timer: Timer = $DashCooldown
@onready var ability_cd_timer: Timer = $AbilityCooldown

const SWORD_REST_ANGLE := 0.35
const SWORD_WINDUP_ANGLE := -1.3
const SWORD_SWING_END_ANGLE := 1.4
const SWORD_SWING_TIME := 0.11
const SWORD_RETURN_TIME := 0.14

var move_input: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.DOWN

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO
var can_dash: bool = true

var elemental_infusion_timer: float = 0.0
var avatar_form_timer: float = 0.0
var second_wind_iframe_timer: float = 0.0
var whirlwind_timer: float = 0.0
var sword_tween: Tween = null

const PROJECTILE_SCENE := preload("res://scenes/projectile/Projectile.tscn")

func _ready() -> void:
	add_to_group("player")
	PlayerStats.reset_for_new_run()
	if sword_pivot:
		sword_pivot.rotation = SWORD_REST_ANGLE

func _physics_process(delta: float) -> void:
	if PlayerStats.is_dead():
		return

	_handle_timers(delta)
	_handle_input()

	if is_dashing:
		velocity = dash_dir * DASH_SPEED
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
	else:
		velocity = move_input * BASE_SPEED * PlayerStats.speed_multiplier()

	move_and_slide()
	_update_facing_visual()

func _handle_timers(delta: float) -> void:
	if elemental_infusion_timer > 0.0:
		elemental_infusion_timer -= delta
	if avatar_form_timer > 0.0:
		avatar_form_timer -= delta
	if second_wind_iframe_timer > 0.0:
		second_wind_iframe_timer -= delta
	if whirlwind_timer > 0.0:
		whirlwind_timer -= delta
		_whirlwind_tick(delta)

func _handle_input() -> void:
	# Controller layout:
	# Left Stick = movement, Right Stick = aim, RT = forward, LT = backward.
	# All controller actions are separate InputMap actions so they can be rebound.
	var controller_move := Input.get_vector(
		"controller_move_left",
		"controller_move_right",
		"controller_move_up",
		"controller_move_down"
	)
	var controller_aim := Input.get_vector(
		"controller_aim_left",
		"controller_aim_right",
		"controller_aim_up",
		"controller_aim_down"
	)

	if controller_aim.length() > 0.25:
		facing = controller_aim.normalized()

	# Left stick gives direct movement. RT/LT add movement in the aim direction,
	# so holding RT makes the player walk forward while the right stick aims.
	move_input = controller_move
	var forward_amount := Input.get_action_strength("controller_forward")
	var backward_amount := Input.get_action_strength("controller_backward")
	var trigger_move := forward_amount - backward_amount
	if abs(trigger_move) > 0.05:
		move_input += facing * trigger_move

	# Keyboard/mouse remains available when the controller is not being used.
	var keyboard_move := Vector2.ZERO
	var aim_dir := get_global_mouse_position() - global_position
	if aim_dir.length() > 0.01:
		keyboard_move = Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)
		if keyboard_move.length() > 1.0:
			keyboard_move = keyboard_move.normalized()
		if controller_move.length() <= 0.25 and abs(trigger_move) <= 0.05:
			facing = aim_dir.normalized()
			var forward_amount_keyboard := Input.get_axis("move_down", "move_up")
			var strafe_amount := Input.get_axis("move_left", "move_right")
			var right_dir: Vector2 = facing.rotated(PI / 2.0)
			move_input = facing * forward_amount_keyboard + right_dir * strafe_amount
			if move_input.length() > 1.0:
				move_input = move_input.normalized()

	if Input.is_action_just_pressed("dash") or Input.is_action_just_pressed("controller_dash"):
		if can_dash and not is_dashing:
			_start_dash()

	if Input.is_action_just_pressed("attack_primary") or Input.is_action_just_pressed("controller_attack_primary"):
		_try_melee_attack()
	if Input.is_action_just_pressed("attack_secondary") or Input.is_action_just_pressed("controller_attack_secondary"):
		_try_ranged_attack()
	if Input.is_action_just_pressed("use_ability") or Input.is_action_just_pressed("controller_use_ability"):
		_try_use_ability()
	if Input.is_action_just_pressed("use_consumable") or Input.is_action_just_pressed("controller_use_consumable"):
		PlayerStats.use_best_consumable()

func _update_facing_visual() -> void:
	if facing.length() > 0.01:
		visual.rotation = facing.angle() + PI / 2.0

# ------------------------------------------------------------------- DASH

func _start_dash() -> void:
	is_dashing = true
	dash_timer = DASH_TIME
	dash_dir = move_input.normalized() if move_input.length() > 0.01 else facing
	can_dash = false
	dash_cd_timer.wait_time = PlayerStats.dash_cooldown()
	dash_cd_timer.start()

	if PlayerStats.has_effect("ability_dash_strike"):
		_dash_strike_damage()

func _on_dash_cooldown_timeout() -> void:
	can_dash = true

func _dash_strike_damage() -> void:
	var dmg := _final_damage(MELEE_DAMAGE * 1.2)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) < 90.0:
			_hit_enemy(enemy, dmg)

# ----------------------------------------------------------------- ATTACKS

func _try_melee_attack() -> void:
	if attack_cd_melee.time_left > 0.0:
		return
	_do_melee_attack()
	attack_cd_melee.wait_time = MELEE_COOLDOWN / PlayerStats.attack_speed_multiplier()
	attack_cd_melee.start()
	attacked.emit("melee")

func _try_ranged_attack() -> void:
	if attack_cd_ranged.time_left > 0.0:
		return
	_do_ranged_attack()
	attack_cd_ranged.wait_time = RANGED_COOLDOWN / PlayerStats.attack_speed_multiplier()
	attack_cd_ranged.start()
	attacked.emit("ranged")

## Applies damage multipliers + crit roll. Returns the final damage number.
func _final_damage(base: float) -> float:
	var dmg := base * PlayerStats.damage_multiplier()
	if avatar_form_timer > 0.0:
		dmg *= 1.8
	if randf() < PlayerStats.crit_chance():
		dmg *= PlayerStats.crit_multiplier()
	return dmg

func _do_melee_attack() -> void:
	var dmg := _final_damage(MELEE_DAMAGE)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var to_enemy: Vector2 = enemy.global_position - global_position
		if to_enemy.length() > MELEE_RANGE:
			continue
		var angle_diff = abs(facing.angle_to(to_enemy.normalized()))
		if angle_diff < deg_to_rad(MELEE_ARC_DEG):
			_hit_enemy(enemy, dmg, MELEE_KNOCKBACK)
	_play_sword_swing()
	_spawn_melee_swoosh()

## Animates the sword swinging through an arc so the melee attack is visible,
## not just an invisible hitbox check.
func _play_sword_swing() -> void:
	if sword_pivot == null:
		return
	if sword_tween != null and sword_tween.is_valid():
		sword_tween.kill()
	sword_pivot.rotation = SWORD_WINDUP_ANGLE
	sword_tween = create_tween()
	sword_tween.tween_property(sword_pivot, "rotation", SWORD_SWING_END_ANGLE, SWORD_SWING_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	sword_tween.tween_property(sword_pivot, "rotation", SWORD_REST_ANGLE, SWORD_RETURN_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## A quick fading "pie slice" showing the actual swing arc/range, for extra
## readability on top of the sword itself.
func _spawn_melee_swoosh() -> void:
	var swoosh := Polygon2D.new()
	var pts := PackedVector2Array()
	var steps := 10
	var half_arc := deg_to_rad(MELEE_ARC_DEG)
	var base_angle := facing.angle()
	pts.append(Vector2.ZERO)
	for i in range(steps + 1):
		var a: float = base_angle - half_arc + (2.0 * half_arc) * float(i) / float(steps)
		pts.append(Vector2(cos(a), sin(a)) * MELEE_RANGE)
	swoosh.polygon = pts
	swoosh.color = Color(0.85, 0.92, 1.0, 0.35)
	add_child(swoosh)
	var tween := create_tween()
	tween.tween_property(swoosh, "modulate:a", 0.0, 0.16)
	tween.tween_callback(swoosh.queue_free)

func _do_ranged_attack() -> void:
	var proj := PROJECTILE_SCENE.instantiate()
	proj.global_position = global_position
	proj.setup(facing, _final_damage(RANGED_DAMAGE), self, "player", RANGED_PROJECTILE_SPEED, RANGED_KNOCKBACK)
	get_tree().current_scene.add_child(proj)

## Central on-hit handler: applies damage plus burn/chill/lifesteal/thorns
## bookkeeping is handled on the *player-takes-damage* side, not here.
func _hit_enemy(enemy: Node, dmg: float, knockback: float = 0.0) -> void:
	enemy.take_damage(dmg, self)
	if knockback > 0.0 and enemy.has_method("apply_knockback"):
		var away: Vector2 = (enemy.global_position - global_position).normalized()
		enemy.apply_knockback(away * knockback)
	if (elemental_infusion_timer > 0.0 or PlayerStats.burn_on_hit_value() > 0.0) and enemy.has_method("apply_burn"):
		var burn_dps: float = max(3.0 if elemental_infusion_timer > 0.0 else 0.0, PlayerStats.burn_on_hit_value())
		enemy.apply_burn(burn_dps)
	if PlayerStats.chill_chance() > 0.0 and randf() < PlayerStats.chill_chance() and enemy.has_method("apply_chill"):
		enemy.apply_chill(2.0)
	var lifesteal := PlayerStats.lifesteal_pct()
	if lifesteal > 0.0:
		PlayerStats.heal(dmg * lifesteal)

# ---------------------------------------------------------------- ABILITIES

func _try_use_ability() -> void:
	if ability_cd_timer.time_left > 0.0:
		return
	var card: ArcanaCard = PlayerStats.active_ability_card()
	if card == null:
		return
	match card.effect_id:
		"ability_whirlwind": _use_whirlwind()
		"ability_second_wind": _use_second_wind()
		"ability_elemental_infusion": _use_elemental_infusion()
		"ability_avatar_form": _use_avatar_form()
		"ability_dash_strike": return  # passive-on-dash, nothing to trigger manually
		_: return
	ability_cd_timer.wait_time = card.ability_cooldown
	ability_cd_timer.start()

func _use_whirlwind() -> void:
	whirlwind_timer = 1.2
	if sword_tween != null and sword_tween.is_valid():
		sword_tween.kill()

func _whirlwind_tick(delta: float) -> void:
	if sword_pivot:
		sword_pivot.rotation += delta * 22.0
	var dmg := _final_damage(MELEE_DAMAGE * 0.5) * delta * 4.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) < 100.0:
			_hit_enemy(enemy, dmg)

func _use_second_wind() -> void:
	PlayerStats.heal(PlayerStats.max_health() * 0.35)
	second_wind_iframe_timer = 1.0

func _use_elemental_infusion() -> void:
	elemental_infusion_timer = 6.0

func _use_avatar_form() -> void:
	avatar_form_timer = 5.0

# ------------------------------------------------------------------ DAMAGE

func take_damage(amount: float, source: Node = null) -> void:
	if is_dashing:
		return  # i-frames during dash
	if avatar_form_timer > 0.0:
		return  # invulnerable during Avatar Form
	if second_wind_iframe_timer > 0.0:
		return  # brief safety window granted by Second Wind

	var thorns := PlayerStats.thorns_pct()
	if thorns > 0.0 and source != null and is_instance_valid(source) and source.has_method("take_damage"):
		source.take_damage(amount * thorns, self)

	PlayerStats.take_damage(amount)
	if PlayerStats.is_dead():
		if PlayerStats.try_revive():
			return
		_die()

func _die() -> void:
	died.emit()
	GameManager.on_player_died()
