extends Enemy
class_name WeepingShade

## Grief Weaver minion: a mournful floating shade that keeps its distance
## and fires a slow shadow bolt -- weak alone, dangerous when it stacks
## damage with the rest of the brood.

const PROJECTILE_SCENE := preload("res://scenes/projectile/Projectile.tscn")

func _ready() -> void:
	max_health = 14.0
	contact_damage = 4.0
	move_speed = 70.0
	attack_range = 240.0
	attack_cooldown = 1.6
	shard_min = 1
	shard_max = 2
	super._ready()

func _do_attack() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	var dir: Vector2 = (player_ref.global_position - global_position).normalized()
	var proj := PROJECTILE_SCENE.instantiate()
	proj.global_position = global_position
	proj.setup(dir, contact_damage, self, "enemy", 260.0)
	get_tree().current_scene.add_child(proj)
