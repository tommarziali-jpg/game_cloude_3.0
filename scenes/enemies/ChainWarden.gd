extends Enemy
class_name ChainWarden

## Iron Inquisitor minion: latches a judgment-chain onto the player on hit,
## dragging them off balance -- a heavier, longer-ranged cousin of the
## Chain Wraith.

func _ready() -> void:
	max_health = 25.0
	contact_damage = 6.0
	move_speed = 95.0
	attack_range = 200.0
	attack_cooldown = 2.0
	shard_min = 1
	shard_max = 3
	super._ready()

func _do_attack() -> void:
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(contact_damage, self)
	if player_ref and player_ref.has_method("external_pull"):
		player_ref.external_pull(global_position, 0.4)
