extends Area2D
class_name Projectile

## Generic projectile used for the player's ranged attack AND for enemy/boss
## ranged attacks. `source_type` decides which group it can damage;
## `source_node` is the attacker (needed so Thorns can reflect damage back
## at the right target when an enemy-fired projectile hits the player).

var direction: Vector2 = Vector2.RIGHT
var speed: float = 480.0
var damage: float = 10.0
var source_type: String = "player"  # "player" or "enemy"
var source_node: Node = null
var knockback: float = 0.0
var lifetime: float = 3.0

@onready var sprite: Polygon2D = $Sprite

func setup(dir: Vector2, dmg: float, source: Node = null, src_type: String = "player", override_speed: float = -1.0, kb: float = 0.0) -> void:
	direction = dir.normalized()
	damage = dmg
	source_node = source
	source_type = src_type
	knockback = kb
	if override_speed > 0.0:
		speed = override_speed
	rotation = direction.angle()
	if sprite:
		sprite.color = Color(1, 0.85, 0.3, 1) if src_type == "player" else Color(0.85, 0.2, 0.25, 1)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if source_type == "player" and body.is_in_group("enemies"):
		_hit_enemy(body)
		queue_free()
	elif source_type == "enemy" and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, source_node)
		queue_free()

func _hit_enemy(enemy: Node) -> void:
	if not enemy.has_method("take_damage"):
		return
	enemy.take_damage(damage, source_node)
	if knockback > 0.0 and enemy.has_method("apply_knockback"):
		enemy.apply_knockback(direction * knockback)
