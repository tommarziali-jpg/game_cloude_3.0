extends Enemy
class_name Broodling

## Grief Weaver minion: tiny, fast spiderling that swarms in numbers --
## low HP, hunts relentlessly, meant to be fought in groups.

func _ready() -> void:
	max_health = 8.0
	contact_damage = 4.0
	move_speed = 165.0
	attack_range = 30.0
	attack_cooldown = 0.8
	shard_min = 1
	shard_max = 2
	super._ready()
