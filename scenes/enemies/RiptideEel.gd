extends Enemy
class_name RiptideEel

## Drowned Choir minion: darts in fast and, on a landed hit, drags the
## player a step further into the current -- the undertow made flesh.

func _ready() -> void:
	max_health = 15.0
	contact_damage = 6.0
	move_speed = 170.0
	attack_range = 34.0
	attack_cooldown = 0.9
	shard_min = 1
	shard_max = 2
	super._ready()

func _do_attack() -> void:
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(contact_damage, self)
	if player_ref and player_ref.has_method("external_pull"):
		player_ref.external_pull(global_position, 0.2)
