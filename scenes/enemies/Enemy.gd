extends CharacterBody2D
class_name Enemy

## Base class for every regular enemy (bosses extend BossBase separately but
## share the same take_damage/knockback/burn/chill/pull contract).
##
## Attacks now play out as a visible windup -> strike -> recover sequence
## instead of dealing damage the instant the cooldown expires: subclasses
## still just override _do_attack() with their unique damage logic (that
## part is unchanged), but it's now only called at the "strike" moment, and
## only actually lands if the player is still roughly in range by then.
## Timing is randomized per attack so identical enemies spawned together
## drift out of sync instead of swinging in lockstep.

signal died(shard_reward: int)

@export var max_health: float = 20.0
@export var contact_damage: float = 8.0
@export var move_speed: float = 90.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.2
@export var shard_min: int = 1
@export var shard_max: int = 4
@export var difficulty_scale: float = 1.0  ## set by Tower.gd on spawn (also boosted for Elites)
@export var is_elite: bool = false          ## set by Tower.gd; tougher, bigger shard payout

## Attack animation timing -- windup telegraphs the hit, strike is the
## instant the damage actually lands, recover is a brief cooldown before the
## enemy can move/attack again. Subclasses may override these before calling
## super._ready() for a snappier or slower-feeling attack.
@export var attack_windup_time: float = 0.32
@export var attack_strike_time: float = 0.14
@export var attack_recover_time: float = 0.18

var current_health: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var pull_velocity: Vector2 = Vector2.ZERO
var burn_dps: float = 0.0
var burn_time_left: float = 0.0
var chill_time_left: float = 0.0
var attack_timer: float = 0.0
var is_attacking: bool = false
var is_telegraphing: bool = false
var is_dead: bool = false
var player_ref: Node = null

@onready var visual: Node2D = $Visual if has_node("Visual") else null

func _ready() -> void:
	add_to_group("enemies")
	if is_elite:
		max_health *= 3.0
		contact_damage *= 1.4
		shard_min = int(shard_min * 3)
		shard_max = int(shard_max * 3)
		scale *= 1.35
	current_health = max_health * difficulty_scale
	max_health = current_health
	contact_damage *= difficulty_scale
	# Random initial offset so enemies spawned together (same type or not)
	# don't all become attack-ready on the same frame.
	attack_timer = randf_range(0.0, attack_cooldown * 0.6)
	call_deferred("_find_player")

func _find_player() -> void:
	player_ref = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if player_ref == null or not is_instance_valid(player_ref):
		_find_player()

	_handle_burn(delta)
	if chill_time_left > 0.0:
		chill_time_left -= delta
	attack_timer = max(0.0, attack_timer - delta)

	var effective_speed: float = move_speed * (0.5 if chill_time_left > 0.0 else 1.0)
	var move_vec := Vector2.ZERO
	if player_ref and is_instance_valid(player_ref):
		var to_player: Vector2 = player_ref.global_position - global_position
		var dist := to_player.length()
		if not is_attacking:
			if dist > attack_range:
				move_vec = to_player.normalized()
			else:
				_try_attack()

	velocity = move_vec * effective_speed + knockback_velocity + pull_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 600.0 * delta)
	pull_velocity = pull_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()

func _handle_burn(delta: float) -> void:
	if burn_time_left > 0.0:
		burn_time_left -= delta
		take_damage(burn_dps * delta, null, true)

# ------------------------------------------------------------- ATTACK CYCLE

func _try_attack() -> void:
	if attack_timer <= 0.0 and not is_attacking:
		is_attacking = true
		_run_attack_sequence()

func _run_attack_sequence() -> void:
	_show_telegraph()
	await get_tree().create_timer(attack_windup_time).timeout
	if is_dead or not is_instance_valid(self):
		return
	_hide_telegraph()
	_show_swipe()
	# Re-check range at the moment of the strike -- the target may have
	# moved during the windup, giving the player a real chance to dodge.
	if player_ref and is_instance_valid(player_ref) and global_position.distance_to(player_ref.global_position) <= attack_range * 1.2:
		_do_attack()
	await get_tree().create_timer(attack_strike_time).timeout
	if is_dead or not is_instance_valid(self):
		return
	await get_tree().create_timer(attack_recover_time).timeout
	if is_dead or not is_instance_valid(self):
		return
	is_attacking = false
	# Re-rolled every cycle (not just once at spawn) so timing keeps drifting
	# and enemies of the same type never lock into a shared rhythm.
	attack_timer = attack_cooldown * randf_range(0.8, 1.3)

## Override in subclasses for unique attack patterns. Default = melee contact
## damage. Called once, at the "strike" instant of the attack animation.
func _do_attack() -> void:
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(contact_damage, self)

func _show_telegraph() -> void:
	is_telegraphing = true
	if visual:
		visual.modulate = Color(1.6, 1.4, 0.65)
		var tween := create_tween()
		tween.tween_property(visual, "scale", Vector2(1.22, 1.22), attack_windup_time * 0.85)

func _hide_telegraph() -> void:
	is_telegraphing = false
	if visual:
		visual.modulate = Color(1, 1, 1)
		var tween := create_tween()
		tween.tween_property(visual, "scale", Vector2(1, 1), 0.1)

## A brief fading "slash" shape toward the player at the strike instant, so
## the attack reads clearly even with simple placeholder shapes.
func _show_swipe() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	var dir: Vector2 = (player_ref.global_position - global_position).normalized()
	var perp: Vector2 = dir.rotated(PI / 2.0)
	var reach: float = min(attack_range, 70.0)
	var swipe := Polygon2D.new()
	swipe.polygon = PackedVector2Array([
		dir * reach * 0.25 + perp * reach * 0.3,
		dir * reach,
		dir * reach * 0.25 - perp * reach * 0.3,
	])
	swipe.color = Color(1.0, 0.35, 0.3, 0.8)
	add_child(swipe)
	var tween := create_tween()
	tween.tween_property(swipe, "modulate:a", 0.0, attack_strike_time + 0.08)
	tween.tween_callback(swipe.queue_free)

# ------------------------------------------------------------------ DAMAGE

func take_damage(amount: float, _source: Node = null, is_dot: bool = false) -> void:
	if is_dead:
		return
	current_health -= amount
	if not is_dot:
		_flash()
	if current_health <= 0.0:
		_die()

func _flash() -> void:
	if visual:
		visual.modulate = Color(1.6, 1.6, 1.6)
		var t := get_tree().create_timer(0.08)
		t.timeout.connect(func():
			if visual and not is_telegraphing: visual.modulate = Color(1, 1, 1)
		)

func apply_knockback(vec: Vector2) -> void:
	knockback_velocity += vec

func apply_pull(vec: Vector2) -> void:
	pull_velocity += vec

func apply_burn(dps: float, duration: float = 3.0) -> void:
	burn_dps = max(burn_dps, dps)
	burn_time_left = max(burn_time_left, duration)

func apply_chill(duration: float = 2.0) -> void:
	chill_time_left = max(chill_time_left, duration)

const PICKUP_ORB_SCENE := preload("res://scenes/pickups/PickupOrb.tscn")

func _die() -> void:
	is_dead = true
	var shards := randi_range(shard_min, shard_max)
	died.emit(shards)
	_spawn_reward_orbs(shards)
	queue_free()

func _spawn_reward_orbs(shard_amount: int) -> void:
	var scene := get_tree().current_scene
	if scene == null or shard_amount <= 0:
		return
	var orb_count: int = clampi(shard_amount, 1, 6)
	var each: float = float(shard_amount) / float(orb_count)
	for i in range(orb_count):
		_spawn_orb(scene, each)

func _spawn_orb(scene: Node, amount: float) -> void:
	var orb: PickupOrb = PICKUP_ORB_SCENE.instantiate()
	orb.value = amount
	orb.global_position = global_position + Vector2(randf_range(-14, 14), randf_range(-14, 14))
	scene.add_child(orb)
