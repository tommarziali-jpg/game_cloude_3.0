extends Area2D
class_name Projectile

## Generic projectile used for player and enemy attacks. Player projectiles
## are marked metallic so Sir Gideon's Magnetic Pull can intercept them.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 480.0
var damage: float = 10.0
var source_type: String = "player"
var source_node: Node = null
var knockback: float = 0.0
var was_critical: bool = false
var lifetime: float = 3.0
var magnetic_active: bool = false

@onready var sprite: Polygon2D = $Sprite

func setup(dir: Vector2, dmg: float, source: Node = null, src_type: String = "player", override_speed: float = -1.0, kb: float = 0.0, critical: bool = false) -> void:
	direction = dir.normalized()
	damage = dmg
	source_node = source
	source_type = src_type
	knockback = kb
	was_critical = critical
	if override_speed > 0.0:
		speed = override_speed
	rotation = direction.angle()
	if sprite:
		sprite.color = Color(1, 0.85, 0.3, 1) if src_type == "player" else Color(0.85, 0.2, 0.25, 1)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_body_entered)
	if source_type == "player":
		add_to_group("metallic_projectiles")

func _physics_process(delta: float) -> void:
	if magnetic_active:
		return
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func magnetize_and_return(magnet_source: Node, return_target: Node, return_damage: float) -> void:
	if magnetic_active or not is_instance_valid(magnet_source) or not is_instance_valid(return_target):
		return
	magnetic_active = true
	collision_layer = 0
	collision_mask = 0

	var start := global_position
	var t := 0.0
	while t < 0.35 and is_instance_valid(self) and is_instance_valid(magnet_source):
		t += get_physics_process_delta_time()
		global_position = start.lerp(magnet_source.global_position, clamp(t / 0.35, 0.0, 1.0))
		await get_tree().physics_frame

	t = 0.0
	var return_start := global_position
	while t < 0.35 and is_instance_valid(self) and is_instance_valid(return_target):
		t += get_physics_process_delta_time()
		global_position = return_start.lerp(return_target.global_position, clamp(t / 0.35, 0.0, 1.0))
		await get_tree().physics_frame

	if is_instance_valid(return_target) and return_target.has_method("take_damage"):
		var context := {"attacker": magnet_source, "target": return_target, "source": magnet_source, "damage": return_damage, "attack_type": "magnetic_return", "is_critical": false, "is_secondary": true, "is_dot": false}
		CombatEvents.publish("attack_hit", context)
		return_target.take_damage(return_damage, magnet_source)
	if is_instance_valid(self):
		queue_free()

func _on_body_entered(body: Node) -> void:
	if magnetic_active:
		return
	if source_type == "player" and body.is_in_group("enemies"):
		_hit_enemy(body)
		queue_free()
	elif source_type == "enemy" and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, source_node)
		queue_free()

func _hit_enemy(enemy: Node) -> void:
	if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
		return
	var context := {"attacker": source_node, "target": enemy, "source": source_node, "damage": damage, "attack_type": "projectile", "is_critical": was_critical, "is_secondary": false, "is_dot": false}
	CombatEvents.publish("attack_hit", context)
	if was_critical:
		CombatEvents.publish("critical_hit", context)
	enemy.take_damage(damage, source_node)
	if knockback > 0.0 and enemy.has_method("apply_knockback"):
		enemy.apply_knockback(direction * knockback)
