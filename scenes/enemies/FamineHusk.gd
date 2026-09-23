extends Enemy
class_name FamineHusk

## Starving King minion: a bloated, slow husk that bursts into a cloud of
## starving flies on death -- telegraphed like EmberHog's blast, but the
## resulting field lingers a moment longer to punish standing in it.

const EXPLOSION_RADIUS := 90.0
const EXPLOSION_DAMAGE := 10.0
const EXPLOSION_TELEGRAPH_TIME := 0.9

func _ready() -> void:
	max_health = 28.0
	contact_damage = 8.0
	move_speed = 58.0
	attack_range = 38.0
	attack_cooldown = 1.5
	shard_min = 2
	shard_max = 4
	super._ready()

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	_play_burst_sequence()

func _play_burst_sequence() -> void:
	if visual:
		visual.modulate = Color(0.85, 0.7, 0.4)
		var tween := create_tween()
		tween.set_loops(3)
		tween.tween_property(visual, "scale", Vector2(1.3, 1.3), EXPLOSION_TELEGRAPH_TIME / 6.0)
		tween.tween_property(visual, "scale", Vector2(1.05, 1.05), EXPLOSION_TELEGRAPH_TIME / 6.0)

	await get_tree().create_timer(EXPLOSION_TELEGRAPH_TIME).timeout
	if not is_instance_valid(self):
		return

	_burst()
	_spawn_burst_visual()

	var shards := randi_range(shard_min, shard_max)
	died.emit(shards)
	_spawn_reward_orbs(shards)
	queue_free()

func _burst() -> void:
	if player_ref and is_instance_valid(player_ref):
		if global_position.distance_to(player_ref.global_position) <= EXPLOSION_RADIUS:
			if player_ref.has_method("take_damage"):
				player_ref.take_damage(EXPLOSION_DAMAGE * difficulty_scale, self)

func _spawn_burst_visual() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var ring := Polygon2D.new()
	var pts := PackedVector2Array()
	var steps := 16
	for i in range(steps):
		var a: float = TAU * float(i) / float(steps)
		pts.append(Vector2(cos(a), sin(a)))
	ring.polygon = pts
	ring.color = Color(0.6, 0.5, 0.25, 0.5)
	ring.scale = Vector2(4, 4)
	ring.global_position = global_position
	scene.add_child(ring)
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(EXPLOSION_RADIUS, EXPLOSION_RADIUS), 0.32) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.34)
	tween.chain().tween_callback(ring.queue_free)
