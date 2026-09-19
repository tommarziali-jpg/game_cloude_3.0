extends Enemy
class_name EchoLarva

## Hollow Chorister minion: very low HP, splits into two weaker copies of
## itself once when killed -- UNLESS the killing blow "overkills" it by more
## than 50% of its max HP (an approximation of "finished with a heavy hit").

const SPLIT_SCENE_PATH := "res://scenes/enemies/EchoLarva.tscn"
var has_split: bool = false
var is_split_child: bool = false

func _ready() -> void:
	max_health = 9.0
	contact_damage = 4.0
	move_speed = 130.0
	attack_range = 32.0
	attack_cooldown = 1.0
	shard_min = 0
	shard_max = 1
	super._ready()

func take_damage(amount: float, source: Node = null, is_dot: bool = false) -> void:
	var overkill := amount >= (max_health * 0.5)
	if current_health - amount <= 0.0 and not has_split and not is_split_child and not overkill:
		has_split = true
		_spawn_splits()
	super.take_damage(amount, source, is_dot)

func _spawn_splits() -> void:
	var split_scene: PackedScene = load(SPLIT_SCENE_PATH)
	for i in range(2):
		var child = split_scene.instantiate()
		get_parent().call_deferred("add_child", child)
		child.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		child.is_split_child = true
		child.has_split = true
		child.difficulty_scale = difficulty_scale
		child.call_deferred("_apply_split_stats")

func _apply_split_stats() -> void:
	max_health = max(3.0, max_health * 0.5)
	current_health = max_health
	shard_max = max(1, int(shard_max * 0.5))
