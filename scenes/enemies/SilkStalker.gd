extends Enemy
class_name SilkStalker

## Grief Weaver minion: trails silk behind it and, on a landed hit, reels
## the player in toward it -- a web-pull melee brute similar to the Chain
## Wraith but with a slower, heavier tug.

func _ready() -> void:
	max_health = 23.0
	contact_damage = 7.0
	move_speed = 100.0
	attack_range = 210.0
	attack_cooldown = 2.1
	shard_min = 1
	shard_max = 3
	super._ready()

func _do_attack() -> void:
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(contact_damage, self)
	if player_ref and player_ref.has_method("external_pull"):
		player_ref.external_pull(global_position, 0.45)
