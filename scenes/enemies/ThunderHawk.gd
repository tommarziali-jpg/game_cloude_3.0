extends Enemy
class_name ThunderHawk

## Static Sovereign minion: a very fast dive-bomber -- low telegraph time,
## short cooldown, hits hard and often. The clearest "kill it first"
## threat in the Static act.

func _ready() -> void:
	max_health = 16.0
	contact_damage = 7.0
	move_speed = 200.0
	attack_range = 34.0
	attack_windup_time = 0.2
	attack_cooldown = 0.8
	shard_min = 1
	shard_max = 3
	super._ready()
