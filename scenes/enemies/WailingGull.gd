extends Enemy
class_name WailingGull

## Drowned Choir minion: circles at range and shrieks a sound-projectile
## that drains stamina on contact -- a flying harasser that punishes
## standing still.

const PROJECTILE_SCENE := preload("res://scenes/projectile/Projectile.tscn")

func _ready() -> void:
	max_health = 12.0
	contact_damage = 0.0
	move_speed = 100.0
	attack_range = 240.0
	attack_cooldown = 1.7
	shard_min = 1
	shard_max = 2
	super._ready()

func _do_attack() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	var dir: Vector2 = (player_ref.global_position - global_position).normalized()
	var proj := PROJECTILE_SCENE.instantiate()
	proj.global_position = global_position
	proj.setup(dir, 3.0, self, "enemy", 300.0)
	get_tree().current_scene.add_child(proj)
	if player_ref.has_method("drain_dash"):
		player_ref.drain_dash(2.0)
