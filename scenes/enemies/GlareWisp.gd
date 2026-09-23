extends Enemy
class_name GlareWisp

## Glass Tyrant minion: hangs back and fires a blinding shard of reflected
## light that saps the player's stamina rather than dealing a big hit --
## a glare that makes you flinch and lose your footing.

const PROJECTILE_SCENE := preload("res://scenes/projectile/Projectile.tscn")

func _ready() -> void:
	max_health = 15.0
	contact_damage = 4.0
	move_speed = 90.0
	attack_range = 250.0
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
	proj.setup(dir, contact_damage * 1.4, self, "enemy", 360.0)
	get_tree().current_scene.add_child(proj)
	if player_ref.has_method("drain_dash"):
		player_ref.drain_dash(1.0)
