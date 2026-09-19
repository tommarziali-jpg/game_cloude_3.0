extends Area2D
class_name PickupOrb

## A Star Shard orb dropped by dead enemies / broken Corruption Crystals.
## Idles briefly, then once the player is within magnet range it drifts
## toward them with increasing speed and is absorbed on contact. If the
## player has an auto-collect effect (Astral Magnetism / Star Compass), the
## magnet range is effectively the whole floor.

const BASE_MAGNET_RADIUS := 170.0
const CATCH_RADIUS := 22.0
const MAX_SPEED := 620.0
const IDLE_TIME := 0.25  ## brief pop-out delay before it can be collected/pulled
const AUTO_COLLECT_RADIUS := 4000.0

@export var value: float = 1.0

@onready var visual: Polygon2D = $Visual

var player_ref: Node = null
var idle_timer: float = IDLE_TIME
var speed: float = 60.0
var bob_time: float = 0.0
var pop_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("pickups")
	pop_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(20, 50)
	call_deferred("_find_player")

func _find_player() -> void:
	player_ref = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	bob_time += delta
	visual.position.y = -4.0 + sin(bob_time * 6.0) * 2.0

	if idle_timer > 0.0:
		idle_timer -= delta
		global_position += pop_dir * delta
		pop_dir = pop_dir.move_toward(Vector2.ZERO, 200.0 * delta)
		return

	if player_ref == null or not is_instance_valid(player_ref):
		_find_player()
		return

	var to_player: Vector2 = player_ref.global_position - global_position
	var dist := to_player.length()

	if dist <= CATCH_RADIUS:
		_collect()
		return

	var magnet_radius: float = AUTO_COLLECT_RADIUS if PlayerStats.has_auto_collect() else (BASE_MAGNET_RADIUS + PlayerStats.pickup_radius_bonus())
	if dist <= magnet_radius:
		speed = min(MAX_SPEED, speed + 1800.0 * delta)
		global_position += to_player.normalized() * speed * delta

func _collect() -> void:
	PlayerStats.add_star_shards(int(round(value)))
	queue_free()
