extends Enemy
class_name EmberHog

## Ember Matriarch minion: slow, tanky. Explodes into a fire AoE ring when
## killed -- but NOT instantly. Death starts a telegraph (the corpse glows
## and swells for EXPLOSION_TELEGRAPH_TIME seconds) before the actual blast
## happens, so the player has a real window to run out of range instead of
## eating unavoidable damage the instant the killing blow lands.

const EXPLOSION_RADIUS := 90.0
const EXPLOSION_DAMAGE := 12.0
const EXPLOSION_TELEGRAPH_TIME := 0.85

func _ready() -> void:
	max_health = 34.0
	contact_damage = 10.0
	move_speed = 65.0
	attack_range = 40.0
	attack_cooldown = 1.4
	shard_min = 2
	shard_max = 4
	super._ready()

func _die() -> void:
	if is_dead:
		return
	# Freeze in place immediately (is_dead halts _physics_process movement/
	# attacks) so the corpse just sits there glowing -- a clear, readable
	# "get away from me" telegraph -- before it actually detonates.
	is_dead = true
	_play_explosion_sequence()

func _play_explosion_sequence() -> void:
	if visual:
		visual.modulate = Color(1.9, 0.55, 0.25)
		var tween := create_tween()
		tween.set_loops(3)
		tween.tween_property(visual, "scale", Vector2(1.35, 1.35), EXPLOSION_TELEGRAPH_TIME / 6.0)
		tween.tween_property(visual, "scale", Vector2(1.1, 1.1), EXPLOSION_TELEGRAPH_TIME / 6.0)

	await get_tree().create_timer(EXPLOSION_TELEGRAPH_TIME).timeout
	if not is_instance_valid(self):
		return

	_explode()
	_spawn_explosion_visual()

	var shards := randi_range(shard_min, shard_max)
	died.emit(shards)
	_spawn_reward_orbs(shards)
	queue_free()

func _explode() -> void:
	if player_ref and is_instance_valid(player_ref):
		if global_position.distance_to(player_ref.global_position) <= EXPLOSION_RADIUS:
			if player_ref.has_method("take_damage"):
				player_ref.take_damage(EXPLOSION_DAMAGE * difficulty_scale, self)

## A quick expanding, fading ring showing the actual blast radius, so the
## explosion itself is as readable as the telegraph leading up to it.
func _spawn_explosion_visual() -> void:
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
	ring.color = Color(1.0, 0.5, 0.2, 0.55)
	ring.scale = Vector2(4, 4)
	ring.global_position = global_position
	scene.add_child(ring)
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(EXPLOSION_RADIUS, EXPLOSION_RADIUS), 0.28) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(ring.queue_free)
