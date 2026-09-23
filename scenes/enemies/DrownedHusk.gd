extends Enemy
class_name DrownedHusk

## Drowned Choir minion: a slow, waterlogged shambler with heavy HP --
## a front-line body meant to be tanked through or kited around, not
## bursted down.

func _ready() -> void:
	max_health = 32.0
	contact_damage = 9.0
	move_speed = 55.0
	attack_range = 40.0
	attack_cooldown = 1.4
	shard_min = 2
	shard_max = 4
	super._ready()
