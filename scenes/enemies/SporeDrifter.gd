extends Enemy
class_name SporeDrifter

## Plague Cantor minion: drifts at range, lobs a slow spore that saps
## stamina on contact instead of dealing a big hit -- pressure through
## attrition rather than burst damage.

const PROJECTILE_SCENE := preload("res://scenes/projectile/Projectile.tscn")

func _ready() -> void:
	max_health = 13.0
	contact_damage = 3.0
	move_speed = 55.0
	attack_range = 230.0
	attack_cooldown = 1.9
	shard_min = 1
	shard_max = 2
	super._ready()

func _do_attack() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	var dir: Vector2 = (player_ref.global_position - global_position).normalized()
	var proj := PROJECTILE_SCENE.instantiate()
	proj.global_position = global_position
	proj.setup(dir, contact_damage, self, "enemy", 220.0)
	get_tree().current_scene.add_child(proj)
	if player_ref.has_method("drain_dash"):
		player_ref.drain_dash(1.5)
