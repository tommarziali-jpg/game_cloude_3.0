extends Node2D

## The main arena-descent orchestrator. Loaded ONCE when the player enters the
## Spire; floors are generated procedurally inside this same running scene.

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const SHOP_SCENE := preload("res://scenes/interactables/Shop.tscn")
const FLOOR_PORTAL_SCENE := preload("res://scenes/interactables/FloorPortal.tscn")
const CORRUPTION_CRYSTAL_SCENE := preload("res://scenes/enemies/CorruptionCrystal.tscn")

const ARENA_RADIUS := 360.0

@onready var arena_center: Vector2 = Vector2.ZERO
@onready var enemy_layer: Node2D = $EnemyLayer
@onready var interactable_layer: Node2D = $InteractableLayer
@onready var ground: Polygon2D = $Ground

var player: Player = null
var current_wave_enemies: Array = []
var current_boss: Node = null
var waiting_for_wave_clear: bool = false

func _ready() -> void:
	arena_center = ground.position
	_spawn_player()
	GameManager.on_floor_entered()
	PlayerStats.refresh_floor_shield()
	_start_floor()

func _process(_delta: float) -> void:
	_clamp_player_to_arena()

func _clamp_player_to_arena() -> void:
	if player == null or not is_instance_valid(player):
		return
	var offset: Vector2 = player.global_position - arena_center
	if offset.length() > ARENA_RADIUS:
		player.global_position = arena_center + offset.normalized() * ARENA_RADIUS

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = arena_center

func _start_floor() -> void:
	waiting_for_wave_clear = false
	if GameManager.is_boss_floor():
		player.global_position = arena_center + Vector2(0, ARENA_RADIUS * 0.65)
		_start_boss_floor()
	else:
		player.global_position = arena_center
		_start_wave(1)

func _start_wave(wave_number: int) -> void:
	GameManager.on_wave_started(wave_number)
	var scene_paths: Array[String] = WaveData.enemies_for_wave(GameManager.current_floor, wave_number, GameManager.waves_for_floor(GameManager.current_floor))
	current_wave_enemies.clear()
	waiting_for_wave_clear = true

	var count := scene_paths.size()
	var elite_index: int = -1
	if GameManager.current_floor >= 3 and randf() < 0.25 + float(GameManager.current_floor) * 0.01:
		elite_index = randi() % max(1, count)

	for i in range(count):
		var angle := TAU * float(i) / float(max(1, count)) + randf_range(-0.2, 0.2)
		var r := randf_range(ARENA_RADIUS * 0.5, ARENA_RADIUS * 0.9)
		var pos: Vector2 = arena_center + Vector2(cos(angle), sin(angle)) * r
		_spawn_enemy(scene_paths[i], pos, i == elite_index)

	_maybe_spawn_corruption_crystal()

func _spawn_enemy(scene_path: String, pos: Vector2, elite: bool = false) -> void:
	var scene: PackedScene = load(scene_path)
	var e = scene.instantiate()
	e.difficulty_scale = GameManager.floor_difficulty_multiplier()
	e.is_elite = elite
	e.global_position = pos
	enemy_layer.add_child(e)
	current_wave_enemies.append(e)
	e.tree_exiting.connect(_on_wave_enemy_removed.bind(e))

func _maybe_spawn_corruption_crystal() -> void:
	if randf() < 0.3:
		var crystal = CORRUPTION_CRYSTAL_SCENE.instantiate()
		var angle := randf_range(0, TAU)
		var r := randf_range(ARENA_RADIUS * 0.3, ARENA_RADIUS * 0.7)
		crystal.difficulty_scale = 1.0
		crystal.global_position = arena_center + Vector2(cos(angle), sin(angle)) * r
		enemy_layer.add_child(crystal)
		current_wave_enemies.append(crystal)
		crystal.tree_exiting.connect(_on_wave_enemy_removed.bind(crystal))

func _on_wave_enemy_removed(e) -> void:
	current_wave_enemies.erase(e)
	if waiting_for_wave_clear and current_wave_enemies.is_empty():
		waiting_for_wave_clear = false
		_on_wave_cleared()

func _on_wave_cleared() -> void:
	var total := GameManager.waves_for_floor(GameManager.current_floor)
	if GameManager.current_wave < total:
		await get_tree().create_timer(1.2).timeout
		_start_wave(GameManager.current_wave + 1)
	else:
		_on_floor_cleared()

func _start_boss_floor() -> void:
	var boss_path := WaveData.boss_scene_for_floor(GameManager.current_floor)
	var scene: PackedScene = load(boss_path)
	current_boss = scene.instantiate()
	current_boss.difficulty_scale = GameManager.floor_difficulty_multiplier()
	current_boss.global_position = arena_center
	current_boss.arena_center = arena_center
	current_boss.arena_radius = ARENA_RADIUS
	enemy_layer.add_child(current_boss)
	current_boss.boss_defeated.connect(_on_boss_defeated)
	if has_node("HUD"):
		$HUD.show_boss(current_boss)

func _on_boss_defeated() -> void:
	current_boss = null
	_on_floor_cleared()

func _on_floor_cleared() -> void:
	GameManager.on_floor_cleared()
	_spawn_reward()

func _spawn_reward() -> void:
	var shop = SHOP_SCENE.instantiate()
	interactable_layer.add_child(shop)
	shop.global_position = arena_center + Vector2(-80, -80)

	var portal = FLOOR_PORTAL_SCENE.instantiate()
	interactable_layer.add_child(portal)
	portal.global_position = arena_center + Vector2(90, 60)
	portal.entered.connect(_descend_to_next_floor)

func _descend_to_next_floor() -> void:
	for child in interactable_layer.get_children():
		child.queue_free()
	for child in enemy_layer.get_children():
		child.queue_free()
	GameManager.advance_to_next_floor()
	GameManager.on_floor_entered()
	PlayerStats.refresh_floor_shield()
	_start_floor()
