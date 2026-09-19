extends Enemy
class_name TuskedPiglet

## Ember Matriarch minion: small, fast, low HP. Hunts in pairs and just
## charges the player relentlessly.

func _ready() -> void:
	max_health = 10.0
	contact_damage = 6.0
	move_speed = 160.0
	attack_range = 34.0
	attack_cooldown = 0.9
	shard_min = 1
	shard_max = 2
	super._ready()
