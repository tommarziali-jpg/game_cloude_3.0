extends Enemy
class_name MirrorWraith

## Glass Tyrant minion: a melee shard-soldier that shatters into a weaker
## copy of itself when killed -- UNLESS the killing blow overkills it by
## more than 50% of its max HP (mirrors EchoLarva's split rule, but reads
## as "the reflection survives the crack" rather than a literal split).

const SPLIT_SCENE_PATH := "res://scenes/enemies/MirrorWraith.tscn"
var has_split: bool = false
var is_split_child: bool = false

func _ready() -> void:
	max_health = 20.0
	contact_damage = 7.0
	move_speed = 105.0
	attack_range = 40.0
	attack_cooldown = 1.1
	shard_min = 1
	shard_max = 3
	super._ready()

func take_damage(amount: float, source: Node = null, is_dot: bool = false) -> void:
	var overkill := amount >= (max_health * 0.5)
	if current_health - amount <= 0.0 and not has_split and not is_split_child and not overkill:
		has_split = true
		_spawn_split()
	super.take_damage(amount, source, is_dot)

func _spawn_split() -> void:
	var split_scene: PackedScene = load(SPLIT_SCENE_PATH)
	var child = split_scene.instantiate()
	get_parent().call_deferred("add_child", child)
	child.global_position = global_position + Vector2(randf_range(-18, 18), randf_range(-18, 18))
	child.is_split_child = true
	child.has_split = true
	child.difficulty_scale = difficulty_scale
	child.call_deferred("_apply_split_stats")

func _apply_split_stats() -> void:
	max_health = max(6.0, max_health * 0.55)
	current_health = max_health
	shard_max = max(1, int(shard_max * 0.5))
