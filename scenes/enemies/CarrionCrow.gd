extends Enemy
class_name CarrionCrow

## Starving King minion: a fast, fragile flying harasser that pecks and
## darts away -- low HP, high speed, meant to be picked off individually
## instead of tanked.

func _ready() -> void:
	max_health = 9.0
	contact_damage = 5.0
	move_speed = 190.0
	attack_range = 32.0
	attack_cooldown = 0.75
	shard_min = 1
	shard_max = 2
	super._ready()
