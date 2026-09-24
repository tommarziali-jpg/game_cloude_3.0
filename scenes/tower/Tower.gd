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
var tester_panel: PanelContainer = null
var tester_floor_spinbox: SpinBox = null
var tester_invincible_toggle: CheckButton = null

func _ready() -> void:
	arena_center = ground.position
	_create_tester_panel()
	_spawn_player()
	GameManager.on_floor_entered()
	PlayerStats.refresh_floor_shield()
	_start_floor()

func _process(_delta: float) -> void:
	_clamp_player_to_arena()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_1:
		_toggle_tester_panel()
		get_viewport().set_input_as_handled()

func _toggle_tester_panel() -> void:
	if tester_panel == null:
		return
	tester_panel.visible = not tester_panel.visible
	if tester_panel.visible and tester_floor_spinbox != null:
		tester_floor_spinbox.value = GameManager.current_floor

func _create_tester_panel() -> void:
	tester_panel = PanelContainer.new()
	tester_panel.name = "TesterPanel"
	tester_panel.visible = false
	tester_panel.position = Vector2(380, 150)
	tester_panel.custom_minimum_size = Vector2(520, 360)
	tester_panel.z_index = 100
	add_child(tester_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	tester_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title := Label.new()
	title.text = "TESTER PANEL"
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)

	var hint := Label.new()
	hint.text = "Press 1 to open/close. Changes apply immediately."
	box.add_child(hint)

	var separator := HSeparator.new()
	box.add_child(separator)

	var floor_row := HBoxContainer.new()
	var floor_label := Label.new()
	floor_label.text = "Jump to floor:"
	floor_label.custom_minimum_size = Vector2(180, 0)
	floor_row.add_child(floor_label)

	tester_floor_spinbox = SpinBox.new()
	tester_floor_spinbox.min_value = 1
	tester_floor_spinbox.max_value = 9999
	tester_floor_spinbox.step = 1
	tester_floor_spinbox.value = 1
	tester_floor_spinbox.custom_minimum_size = Vector2(120, 42)
	tester_floor_spinbox.tooltip_text = "Enter any floor from 1 to 9999."
	floor_row.add_child(tester_floor_spinbox)

	var jump_button := Button.new()
	jump_button.text = "GO"
	jump_button.custom_minimum_size = Vector2(100, 42)
	jump_button.pressed.connect(_tester_jump_to_selected_floor)
	floor_row.add_child(jump_button)
	box.add_child(floor_row)

	tester_invincible_toggle = CheckButton.new()
	tester_invincible_toggle.text = "Invincible"
	tester_invincible_toggle.tooltip_text = "Prevents all player damage while enabled."
	tester_invincible_toggle.toggled.connect(_tester_set_invincible)
	box.add_child(tester_invincible_toggle)

	var boss_hint := Label.new()
	boss_hint.text = "Tip: jump directly to a boss floor to test a boss fight."
	boss_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(boss_hint)

	var close_button := Button.new()
	close_button.text = "Close (1)"
	close_button.custom_minimum_size = Vector2(0, 42)
	close_button.pressed.connect(_toggle_tester_panel)
	box.add_child(close_button)

func _tester_set_invincible(enabled: bool) -> void:
	PlayerStats.tester_invincible = enabled

func _tester_jump_to_selected_floor() -> void:
	if tester_floor_spinbox == null:
		return
	_set_tester_floor(int(tester_floor_spinbox.value))
	tester_panel.visible = false

func _set_tester_floor(target_floor: int) -> void:
	var floor_number := clampi(target_floor, 1, 9999)
	# Remove the current floor immediately so a boss/wave from the old floor
	# cannot remain active after the tester jump.
	for child in interactable_layer.get_children():
		child.free()
	for child in enemy_layer.get_children():
		child.free()
	current_wave_enemies.clear()
	current_boss = null
	waiting_for_wave_clear = false

	GameManager.current_floor = floor_number
	GameManager.current_wave = 0
	GameManager.run_active = true
	PlayerStats.current_health = PlayerStats.max_health()
	PlayerStats.rust_defense_reduction_pct = 0.0
	PlayerStats.rust_defense_timer = 0.0
	PlayerStats.health_changed.emit(PlayerStats.current_health, PlayerStats.max_health())
	GameManager.on_floor_entered()
	PlayerStats.refresh_floor_shield()
	_start_floor()


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
