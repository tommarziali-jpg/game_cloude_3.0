extends Enemy
class_name CorruptionCrystal

## A stationary breakable hazard scattered around some floors. Doesn't move
## or attack -- just sits there with HP. Breaking one showers the floor with
## Star Shards, per the "breaking corruption crystals" currency source.

func _ready() -> void:
	max_health = 18.0
	contact_damage = 0.0
	move_speed = 0.0
	attack_range = 0.0
	shard_min = 4
	shard_max = 9
	super._ready()

func _physics_process(_delta: float) -> void:
	if is_dead:
		return
	_handle_burn(_delta)
	velocity = knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 600.0 * _delta)
	move_and_slide()

func _try_attack() -> void:
	pass  # crystals never attack

func _do_attack() -> void:
	pass
