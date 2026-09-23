extends Enemy
class_name StaticDrone

## Static Sovereign minion: nearly stationary, sits in the arena as a
## hazard rather than hunting the player -- but a contact hit drains a
## large chunk of dash charge, so it can't just be ignored.

func _ready() -> void:
	max_health = 24.0
	contact_damage = 1.0
	move_speed = 10.0
	attack_range = 42.0
	attack_cooldown = 1.0
	shard_min = 1
	shard_max = 3
	super._ready()

func _do_attack() -> void:
	if player_ref and player_ref.has_method("drain_dash"):
		player_ref.drain_dash(3.5)
	elif player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(contact_damage, self)
