extends Enemy
class_name VoidMoth

## Umbral Warden minion: slow-flying, drains the player's dash charge on
## contact instead of dealing HP damage.

func _ready() -> void:
	max_health = 14.0
	contact_damage = 0.0
	move_speed = 75.0
	attack_range = 36.0
	attack_cooldown = 1.6
	shard_min = 1
	shard_max = 2
	super._ready()

func _do_attack() -> void:
	if player_ref and player_ref.has_method("drain_dash"):
		player_ref.drain_dash(2.5)
	elif player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(3.0, self)
