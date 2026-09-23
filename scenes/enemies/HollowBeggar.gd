extends Enemy
class_name HollowBeggar

## Plague Cantor minion: a desperate, starved melee striker that feeds off
## whatever it hits -- every landed attack heals it for half the damage
## dealt, so it needs to be killed fast or it outlasts a sloppy fight.

func _ready() -> void:
	max_health = 18.0
	contact_damage = 6.0
	move_speed = 100.0
	attack_range = 36.0
	attack_cooldown = 1.2
	shard_min = 1
	shard_max = 3
	super._ready()

func _do_attack() -> void:
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(contact_damage, self)
		current_health = min(max_health, current_health + contact_damage * 0.5)
