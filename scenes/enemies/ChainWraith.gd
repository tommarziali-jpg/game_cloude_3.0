extends Enemy
class_name ChainWraith

## Hollow Chorister minion: dashes in and latches a chain onto the player,
## yanking them off balance before dealing a small hit.

func _ready() -> void:
	max_health = 22.0
	contact_damage = 5.0
	move_speed = 110.0
	attack_range = 220.0  ## chain reaches further than contact
	attack_cooldown = 2.2
	shard_min = 1
	shard_max = 3
	super._ready()

func _do_attack() -> void:
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(contact_damage, self)
	if player_ref and player_ref.has_method("external_pull"):
		player_ref.external_pull(global_position, 0.35)
