extends Enemy
class_name StarvedWretch

## Starving King minion: a gaunt melee attacker that heals itself for half
## of every hit it lands -- it does not stop coming until it is dead or
## fed.

func _ready() -> void:
	max_health = 19.0
	contact_damage = 6.0
	move_speed = 110.0
	attack_range = 36.0
	attack_cooldown = 1.1
	shard_min = 1
	shard_max = 3
	super._ready()

func _do_attack() -> void:
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(contact_damage, self)
		current_health = min(max_health, current_health + contact_damage * 0.5)
