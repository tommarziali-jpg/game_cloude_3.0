extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/TopLeft/HealthBar
@onready var health_label: Label = $Control/TopLeft/HealthBar/HealthLabel
@onready var arcana_row: HBoxContainer = $Control/TopLeft/ArcanaRow
@onready var artifact_caption: Label = $Control/TopLeft/ArtifactCaption
@onready var artifact_row: HBoxContainer = $Control/TopLeft/ArtifactRow
@onready var shard_label: Label = $Control/TopRight/ShardLabel
@onready var consumable_caption: Label = $Control/TopRight/ConsumableCaption
@onready var consumable_row: HBoxContainer = $Control/TopRight/ConsumableRow
@onready var buff_label: Label = $Control/TopRight/BuffLabel
@onready var floor_label: Label = $Control/TopCenter/FloorLabel
@onready var wave_label: Label = $Control/TopCenter/WaveLabel
@onready var boss_bar_holder: Control = $Control/BossBarHolder
@onready var boss_bar: ProgressBar = $Control/BossBarHolder/BossBar
@onready var boss_name_label: Label = $Control/BossBarHolder/BossNameLabel
@onready var ability_label: Label = $Control/BottomLeft/AbilityLabel
@onready var banner_panel: PanelContainer = $Control/BannerLayer/BannerPanel
@onready var banner_title: Label = $Control/BannerLayer/BannerPanel/BannerVBox/BannerTitle
@onready var banner_subtitle: Label = $Control/BannerLayer/BannerPanel/BannerVBox/BannerSubtitle

var banner_queue: Array = []
var banner_playing: bool = false
var boss_ref: Node = null

func _ready() -> void:
	PlayerStats.health_changed.connect(_on_health_changed)
	PlayerStats.star_shards_changed.connect(_on_shards_changed)
	PlayerStats.arcana_changed.connect(_refresh_arcana_row)
	PlayerStats.artifacts_changed.connect(_refresh_artifacts)
	PlayerStats.consumables_changed.connect(_refresh_consumables)
	PlayerStats.card_acquired.connect(_on_card_acquired)
	PlayerStats.artifact_acquired.connect(_on_artifact_acquired)
	PlayerStats.arcana_slot_gained.connect(_on_arcana_slot_gained)
	GameManager.floor_started.connect(_on_floor_started)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.floor_cleared.connect(_on_floor_cleared)

	_on_health_changed(PlayerStats.current_health, PlayerStats.max_health())
	_on_shards_changed(PlayerStats.star_shards)
	boss_bar_holder.visible = false
	banner_panel.pivot_offset = banner_panel.custom_minimum_size / 2.0
	_refresh_arcana_row()
	_refresh_artifacts()
	_refresh_consumables()

func _process(_delta: float) -> void:
	if boss_ref != null and is_instance_valid(boss_ref):
		boss_bar.max_value = boss_ref.max_health
		boss_bar.value = boss_ref.current_health
	elif boss_bar_holder.visible:
		boss_bar_holder.visible = false
		boss_ref = null
	_refresh_buffs()
	_refresh_ability_hint()

func show_boss(boss: Node) -> void:
	boss_ref = boss
	boss_bar_holder.visible = true
	if boss.get("boss_display_name") != null:
		boss_name_label.text = boss.boss_display_name

# ---------------------------------------------------------------- ARCANA ROW

## Always remove_child() (immediate) before queue_free() (deferred) so a
## rapid double-refresh can never see a stale node still attached.
func _clear_row(row: Node) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()

func _refresh_arcana_row() -> void:
	_clear_row(arcana_row)
	for card in PlayerStats.equipped_arcana:
		var slot := _make_arcana_slot_widget(card)
		arcana_row.add_child(slot)

func _make_arcana_slot_widget(card: ArcanaCard) -> Control:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(36, 36)
	if card == null:
		var empty_label := Label.new()
		empty_label.text = "+"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.modulate = Color(0.5, 0.5, 0.55, 0.6)
		box.add_child(empty_label)
	else:
		var icon := TextureRect.new()
		icon.texture = IconGenerator.make_icon(card.icon_kind, card.type_color(), 32)
		icon.custom_minimum_size = Vector2(32, 32)
		icon.tooltip_text = "%s (%s)\n%s" % [card.card_name, card.type_name(), card.description]
		box.add_child(icon)
	return box

## Artifacts and Consumables are shown as small icons (not cards), with
## their name/description revealed in a native hover tooltip -- matching the
## Shop's presentation instead of duplicating card-style widgets in the HUD.
func _refresh_artifacts() -> void:
	_clear_row(artifact_row)
	artifact_caption.text = "Artifacts (%d)" % PlayerStats.owned_artifacts.size()
	for artifact in PlayerStats.owned_artifacts:
		var icon := TextureRect.new()
		icon.texture = IconGenerator.make_icon(artifact.icon_kind, artifact.rarity_color(), 26)
		icon.custom_minimum_size = Vector2(26, 26)
		icon.tooltip_text = "%s (%s)\n%s" % [artifact.artifact_name, artifact.rarity_name(), artifact.description]
		artifact_row.add_child(icon)

func _refresh_consumables() -> void:
	_clear_row(consumable_row)
	var total := 0
	for id in PlayerStats.consumable_inventory.keys():
		var entry: Dictionary = PlayerStats.consumable_inventory[id]
		var item: Consumable = entry["item"]
		var count: int = entry["count"]
		total += count
		var box := PanelContainer.new()
		box.custom_minimum_size = Vector2(26, 26)
		var icon := TextureRect.new()
		icon.texture = IconGenerator.make_icon(item.icon_kind, item.color, 22)
		icon.custom_minimum_size = Vector2(22, 22)
		box.add_child(icon)
		box.tooltip_text = "%s x%d\n%s" % [item.consumable_name, count, item.description]
		consumable_row.add_child(box)
	consumable_caption.text = "Consumables (%d, press R)" % total

func _refresh_buffs() -> void:
	var parts: Array[String] = []
	if PlayerStats.temp_dmg_timer > 0.0:
		parts.append("Might %ds" % ceil(PlayerStats.temp_dmg_timer))
	if PlayerStats.temp_speed_timer > 0.0:
		parts.append("Haste %ds" % ceil(PlayerStats.temp_speed_timer))
	if PlayerStats.temp_hp_timer > 0.0:
		parts.append("Fortitude %ds" % ceil(PlayerStats.temp_hp_timer))
	if PlayerStats.shield_charges > 0:
		parts.append("Shield x%d" % PlayerStats.shield_charges)
	buff_label.text = " | ".join(parts)

func _refresh_ability_hint() -> void:
	var card: ArcanaCard = PlayerStats.active_ability_card()
	if card == null:
		ability_label.text = ""
	else:
		ability_label.text = "Ability (E): %s" % card.card_name

func _on_health_changed(current: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current
	health_label.text = "%d / %d" % [int(current), int(max_hp)]

func _on_shards_changed(amount: int) -> void:
	shard_label.text = "Star Shards: %d" % amount

func _on_card_acquired(card: ArcanaCard) -> void:
	_queue_banner("ARCANA ACQUIRED", card.card_name)

func _on_artifact_acquired(artifact: Artifact) -> void:
	_queue_banner("ARTIFACT FOUND", artifact.artifact_name)

func _on_arcana_slot_gained(new_count: int) -> void:
	_queue_banner("BOSS DEFEATED!", "New Arcana slot unlocked (%d total)" % new_count)

func _on_floor_started(floor_number: int, is_boss: bool) -> void:
	floor_label.text = "Floor %d" % floor_number
	if is_boss:
		wave_label.text = "-- BOSS FLOOR --"

func _on_wave_started(wave_number: int, total_waves: int) -> void:
	wave_label.text = "Wave %d / %d" % [wave_number, total_waves]

func _on_floor_cleared(_floor_number: int) -> void:
	wave_label.text = "Floor Cleared! Shop & Portal are open."

func _flash(node: Control) -> void:
	node.modulate = Color(1.4, 1.4, 0.6)
	var tween := create_tween()
	tween.tween_property(node, "modulate", Color(1, 1, 1), 0.6)

# ---------------------------------------------------------------- BIG BANNER

func _queue_banner(title_text: String, subtitle_text: String) -> void:
	banner_queue.append([title_text, subtitle_text])
	if not banner_playing:
		_play_next_banner()

func _play_next_banner() -> void:
	if banner_queue.is_empty():
		banner_playing = false
		return
	banner_playing = true
	var data: Array = banner_queue.pop_front()
	banner_title.text = data[0]
	banner_subtitle.text = data[1]

	banner_panel.scale = Vector2(0.4, 0.4)
	banner_panel.modulate = Color(1, 1, 1, 0)

	var tween := create_tween()
	tween.tween_property(banner_panel, "scale", Vector2(1.08, 1.08), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(banner_panel, "modulate:a", 1.0, 0.15)
	tween.tween_property(banner_panel, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_interval(1.3)
	tween.tween_property(banner_panel, "modulate:a", 0.0, 0.35)
	tween.tween_callback(_play_next_banner)
