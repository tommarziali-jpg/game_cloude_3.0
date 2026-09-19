extends Enemy
class_name ShadeClone

## Umbral Warden minion: copies whichever attack slot the player last used
## (melee lunge or a shadow projectile), at reduced damage.

const PROJECTILE_SCENE := preload("res://scenes/projectile/Projectile.tscn")

func _ready() -> void:
	max_health = 26.0
	contact_damage = 7.0
	move_speed = 100.0
	attack_range = 260.0
	attack_cooldown = 1.8
	shard_min = 1
	shard_max = 2
	super._ready()

func _do_attack() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return
	var to_player: Vector2 = (player_ref.global_position - global_position).normalized()
	if randf() < 0.5:
		var proj := PROJECTILE_SCENE.instantiate()
		proj.global_position = global_position
		proj.setup(to_player, contact_damage * 1.2, self, "enemy", 380.0)
		get_tree().current_scene.add_child(proj)
	else:
		if global_position.distance_to(player_ref.global_position) <= 70.0:
			if player_ref.has_method("take_damage"):
				player_ref.take_damage(contact_damage * 1.4, self)
