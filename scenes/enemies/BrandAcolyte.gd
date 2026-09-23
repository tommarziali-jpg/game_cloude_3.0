extends Enemy
class_name BrandAcolyte

## Iron Inquisitor minion: a ranged zealot that hurls a branding-iron
## projectile in a straight line.

const PROJECTILE_SCENE := preload("res://scenes/projectile/Projectile.tscn")

func _ready() -> void:
	max_health = 17.0
	contact_damage = 5.0
	move_speed = 80.0
	attack_range = 270.0
	attack_cooldown = 1.6
	shard_min = 1
	shard_max = 3
	super._ready()

func _do_attack() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	var dir: Vector2 = (player_ref.global_position - global_position).normalized()
	var proj := PROJECTILE_SCENE.instantiate()
	proj.global_position = global_position
	proj.setup(dir, contact_damage * 1.6, self, "enemy", 400.0)
	get_tree().current_scene.add_child(proj)
