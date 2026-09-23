extends Enemy
class_name VainDuelist

## Glass Tyrant minion: fast, arrogant, closes distance quickly. On a
## landed hit it yanks the player a step closer -- "come admire me" --
## setting them up to be hit again before they can back off.

func _ready() -> void:
	max_health = 14.0
	contact_damage = 6.0
	move_speed = 175.0
	attack_range = 36.0
	attack_cooldown = 0.85
	shard_min = 1
	shard_max = 2
	super._ready()

func _do_attack() -> void:
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(contact_damage, self)
	if player_ref and player_ref.has_method("external_pull"):
		player_ref.external_pull(global_position, 0.15)
