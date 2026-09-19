extends Enemy
class_name BossBase

## Shared boss framework: phase-based attack pattern queue, automatic enrage
## at 50% HP, and minion-spawn tracking so leftover minions are cleaned up
## when the boss dies. Each concrete boss just fills `attack_pattern` with
## method names and implements those methods + `spawn_minions()`.
##
## On death, per the Arcana Descent redesign, bosses no longer drop a unique
## weapon. Instead they grant the player an extra Arcana slot, a guaranteed
## Artifact, and a large burst of Star Shards -- see GameManager.on_boss_defeated().

signal boss_defeated

@export var boss_display_name: String = "Unnamed Warden"

var attack_pattern: Array[String] = []  ## method names, called round-robin
var attack_index: int = 0
var attack_timer: float = 1.5           ## time until next attack decision
var has_enraged: bool = false
var spawned_minions: Array = []
var is_busy: bool = false  ## set true by attacks that manually control movement (e.g. charges)
var roam_target: Vector2 = Vector2.ZERO
var arena_radius: float = 260.0
var arena_center: Vector2 = Vector2.ZERO

func _ready() -> void:
	shard_min = 40
	shard_max = 70
	attack_range = 500.0  # unused directly (bosses use their own attack pattern, not Enemy's contact gating)
	super._ready()
	arena_center = global_position
	_pick_new_roam_target()

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

	if is_busy:
		return  # attack routine is manually driving position this frame

	_roam(delta)
	velocity += knockback_velocity + pull_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 400.0 * delta)
	pull_velocity = pull_velocity.move_toward(Vector2.ZERO, 400.0 * delta)
	move_and_slide()

func _roam(delta: float) -> void:
	if global_position.distance_to(roam_target) < 20.0:
		_pick_new_roam_target()
	var dir: Vector2 = (roam_target - global_position).normalized()
	velocity = dir * move_speed * 0.5

func _pick_new_roam_target() -> void:
	var angle := randf_range(0, TAU)
	var r := randf_range(0, arena_radius * 0.7)
	roam_target = arena_center + Vector2(cos(angle), sin(angle)) * r

func _run_next_attack() -> void:
	if attack_pattern.is_empty():
		return
	var method_name: String = attack_pattern[attack_index % attack_pattern.size()]
	attack_index += 1
	if has_method(method_name):
		call(method_name)
	attack_timer = 2.2  # default gap; individual attacks can override via set_next_attack_delay()

func set_next_attack_delay(t: float) -> void:
	attack_timer = t

## Override in each boss.
func enrage() -> void:
	pass

func spawn_minion(scene_path: String, offset: Vector2) -> void:
	var scene: PackedScene = load(scene_path)
	var m = scene.instantiate()
	get_parent().call_deferred("add_child", m)
	m.global_position = global_position + offset
	m.difficulty_scale = difficulty_scale
	spawned_minions.append(m)

func _die() -> void:
	for m in spawned_minions:
		if is_instance_valid(m):
			m.queue_free()
	is_dead = true
	_spawn_reward_orbs(randi_range(shard_min, shard_max))
	GameManager.on_boss_defeated(self)
	boss_defeated.emit()
	died.emit(0)
	queue_free()

## Helper: fires a projectile from the boss toward a direction (used by many attacks).
const _PROJECTILE_SCENE_PATH := "res://scenes/projectile/Projectile.tscn"
func fire_projectile(dir: Vector2, dmg: float, speed: float = 300.0) -> void:
	var scene: PackedScene = load(_PROJECTILE_SCENE_PATH)
	var proj = scene.instantiate()
	proj.global_position = global_position
	proj.setup(dir, dmg, self, "enemy", speed)
	get_tree().current_scene.add_child(proj)

func player_pos() -> Vector2:
	if player_ref and is_instance_valid(player_ref):
		return player_ref.global_position
	return global_position
