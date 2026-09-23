extends Enemy
class_name SparkWisp

## Static Sovereign minion: a crackling ranged pest that fires a fast bolt
## and, on contact, shocks the player's stamina reserves.

const PROJECTILE_SCENE := preload("res://scenes/projectile/Projectile.tscn")

func _ready() -> void:
	max_health = 11.0
	contact_damage = 3.0
	move_speed = 120.0
	attack_range = 260.0
	attack_cooldown = 1.4
	shard_min = 1
	shard_max = 2
	super._ready()

func _do_attack() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	var dir: Vector2 = (player_ref.global_position - global_position).normalized()
	var proj := PROJECTILE_SCENE.instantiate()
	proj.global_position = global_position
	proj.setup(dir, contact_damage * 1.8, self, "enemy", 460.0)
	get_tree().current_scene.add_child(proj)
	if player_ref.has_method("drain_dash"):
		player_ref.drain_dash(1.0)
