extends Area2D
class_name Shop

## The single shop that appears on every floor after it's cleared. Styled
## after Slay the Spire's shop screen: Arcana Cards are shown as real cards
## (full description text baked in), while Artifacts and Consumables are
## shown as small relic/potion icons in their own row -- NOT as cards -- and
## reveal their name/description/cost in a native hover tooltip, exactly
## like Slay the Spire's relic shelf.
##
## NOTE on a fixed crash: this used to tear down and rebuild a
## GridContainer-inside-a-ScrollContainer every time the shop redrew (using
## queue_free() alone, leaving stale nodes attached until end-of-frame while
## new ones were immediately added on top). That combination could trigger a
## Godot layout/size-negotiation stack overflow. The fix here is twofold:
## (1) the shop's static frame (background, title, buttons) is now built
## ONCE in _open_shop(); redraws only clear+rebuild the small `content_area`
## sub-tree, and (2) clearing always calls remove_child() (immediate, safe to
## iterate over) before queue_free() (deferred), so no stale/duplicate nodes
## can ever coexist with freshly-built ones. The GridContainer+ScrollContainer
## combo is also gone entirely, replaced by simple fixed-size rows.

const CARD_OFFER_COUNT := 3
const ARTIFACT_OFFER_COUNT := 3
const CONSUMABLE_OFFER_COUNT := 3

const CARD_COST_BY_TYPE := {0: 25, 2: 35, 3: 60, 1: 80}  # Minor/Corrupted/Astral/Major
const ARTIFACT_COST_BY_RARITY := {0: 45, 1: 90, 2: 160}  # Common/Rare/Legendary
const FUSE_COST := 25
const REMOVE_COST := 15
const BASE_REROLL_COST := 20

@onready var prompt_label: Label = $PromptLabel

var canvas_layer: CanvasLayer = null
var shop_panel: Control = null
var content_area: VBoxContainer = null
var shard_label: Label = null
var reroll_btn: Button = null

var player_inside: bool = false
var card_offers: Array[ArcanaCard] = []
var artifact_offers: Array[Artifact] = []
var consumable_offers: Array[Consumable] = []
var reroll_count: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt_label.visible = false
	_roll_offers()

func _roll_offers() -> void:
	card_offers = ArcanaDatabase.random_choices(CARD_OFFER_COUNT, PlayerStats.unlocked_card_tier)

	artifact_offers.clear()
	for i in range(ARTIFACT_OFFER_COUNT):
		var a := ArtifactDatabase.random_weighted()
		if a != null:
			artifact_offers.append(a)

	var pool := ConsumableDatabase.all_purchasable()
	pool.shuffle()
	consumable_offers.clear()
	for i in range(min(CONSUMABLE_OFFER_COUNT, pool.size())):
		consumable_offers.append(pool[i])

func _reroll_cost() -> int:
	return BASE_REROLL_COST + reroll_count * 10

func _process(_delta: float) -> void:
	if player_inside and shop_panel == null and Input.is_action_just_pressed("interact"):
		_open_shop()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = true
		if shop_panel == null:
			prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false
		prompt_label.visible = false

# ------------------------------------------------------------------ WINDOW

## Anchors a Control to the exact center of the screen/camera view using
## symmetric offsets around a single center anchor point (rather than
## setting .size then .position separately, which previously caused shop
## windows to appear off-center).
func _center_control(control: Control, w: float, h: float) -> void:
	control.set_anchors_preset(Control.PRESET_CENTER)
	control.offset_left = -w / 2.0
	control.offset_top = -h / 2.0
	control.offset_right = w / 2.0
	control.offset_bottom = h / 2.0

## Always removes AND frees children: remove_child() first (immediate, so a
## node can never be "seen" twice across two rebuilds in the same frame),
## then queue_free() to actually deallocate it a moment later.
func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _open_shop() -> void:
	prompt_label.visible = false
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 20  # draw above the HUD and everything else
	add_child(canvas_layer)

	shop_panel = Control.new()
	_center_control(shop_panel, 940, 680)
	canvas_layer.add_child(shop_panel)

	_build_static_frame()
	_show_main_view()

func _close_shop() -> void:
	if canvas_layer:
		canvas_layer.queue_free()
	canvas_layer = null
	shop_panel = null
	content_area = null
	shard_label = null
	reroll_btn = null

func _refresh_shard_label() -> void:
	if shard_label:
		shard_label.text = "Star Shards: %d" % PlayerStats.star_shards

## Builds the parts of the shop that never change (background, title,
## Star Shard counter, the button row) exactly once. Only `content_area`
## gets cleared and rebuilt after that, for Reroll / Manage Arcana / Back.
func _build_static_frame() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.07, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_panel.add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_top = 12
	root.offset_right = -16
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 10)
	shop_panel.add_child(root)

	var title := Label.new()
	title.text = "Shop"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.modulate = Color(1.0, 0.75, 0.2)
	root.add_child(title)

	shard_label = Label.new()
	shard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shard_label.modulate = Color(0.75, 0.45, 1.0)
	root.add_child(shard_label)
	_refresh_shard_label()

	content_area = VBoxContainer.new()
	content_area.add_theme_constant_override("separation", 14)
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content_area)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 10)
	root.add_child(button_row)

	reroll_btn = Button.new()
	reroll_btn.text = "Reroll Selection (%d)" % _reroll_cost()
	reroll_btn.pressed.connect(_do_reroll)
	button_row.add_child(reroll_btn)

	var close_btn := Button.new()
	close_btn.text = "Leave"
	close_btn.pressed.connect(_close_shop)
	button_row.add_child(close_btn)

func _do_reroll() -> void:
	if PlayerStats.spend_star_shards(_reroll_cost()):
		reroll_count += 1
		reroll_btn.text = "Reroll Selection (%d)" % _reroll_cost()
		_roll_offers()
		_refresh_shard_label()
		_show_main_view()

# -------------------------------------------------------------------- MAIN

func _show_main_view() -> void:
	_clear(content_area)

	var cards_title := Label.new()
	cards_title.text = "Arcana Cards"
	cards_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cards_title.add_theme_font_size_override("font_size", 15)
	cards_title.modulate = Color(0.85, 0.8, 0.9)
	content_area.add_child(cards_title)

	var cards_row := HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 16)
	content_area.add_child(cards_row)
	for card in card_offers:
		cards_row.add_child(_make_card_widget(card))

	var relics_title := Label.new()
	relics_title.text = "Artifacts  (hover to inspect)"
	relics_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relics_title.add_theme_font_size_override("font_size", 15)
	relics_title.modulate = Color(0.85, 0.8, 0.9)
	content_area.add_child(relics_title)

	var relics_row := HBoxContainer.new()
	relics_row.alignment = BoxContainer.ALIGNMENT_CENTER
	relics_row.add_theme_constant_override("separation", 14)
	content_area.add_child(relics_row)
	for artifact in artifact_offers:
		relics_row.add_child(_make_relic_widget(artifact))
	relics_row.add_child(_make_manage_arcana_widget())

	var potions_title := Label.new()
	potions_title.text = "Consumables  (hover to inspect)"
	potions_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	potions_title.add_theme_font_size_override("font_size", 15)
	potions_title.modulate = Color(0.85, 0.8, 0.9)
	content_area.add_child(potions_title)

	var potions_row := HBoxContainer.new()
	potions_row.alignment = BoxContainer.ALIGNMENT_CENTER
	potions_row.add_theme_constant_override("separation", 14)
	content_area.add_child(potions_row)
	for item in consumable_offers:
		potions_row.add_child(_make_potion_widget(item))

# --------------------------------------------------------------- CARD (BIG)

func _make_card_widget(card: ArcanaCard) -> Panel:
	var box := Panel.new()
	box.custom_minimum_size = Vector2(200, 250)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 8
	v.offset_top = 8
	v.offset_right = -8
	v.offset_bottom = -8
	box.add_child(v)

	var type_label := Label.new()
	type_label.text = "%s -- %s" % [card.type_name(), card.theme]
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.modulate = card.type_color()
	type_label.add_theme_font_size_override("font_size", 11)
	v.add_child(type_label)

	var icon := TextureRect.new()
	icon.texture = IconGenerator.make_icon(card.icon_kind, card.type_color(), 48)
	icon.custom_minimum_size = Vector2(48, 48)
	var icon_center := CenterContainer.new()
	icon_center.add_child(icon)
	v.add_child(icon_center)

	var name_label := Label.new()
	name_label.text = card.card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.add_theme_font_size_override("font_size", 14)
	v.add_child(name_label)

	# The card's effect is written directly on the card, Slay the Spire style,
	# rather than needing a separate lookup or tooltip.
	var desc_label := Label.new()
	desc_label.text = card.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.custom_minimum_size = Vector2(0, 42)
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	v.add_child(desc_label)

	var cost: int = CARD_COST_BY_TYPE.get(card.arcana_type, 30)
	var buy_btn := Button.new()
	buy_btn.text = "Buy (%d)" % cost
	buy_btn.pressed.connect(func():
		if PlayerStats.first_empty_slot() == -1:
			buy_btn.text = "No free slot!"
			return
		if PlayerStats.spend_star_shards(cost):
			PlayerStats.add_card_to_first_empty_slot(card)
			buy_btn.text = "Bought!"
			buy_btn.disabled = true
			_refresh_shard_label()
	)
	v.add_child(buy_btn)
	return box

# ------------------------------------------------------- RELIC / POTION ICONS

## Small icon-only buttons (Slay the Spire relic-shelf style) with the name,
## description, and price revealed in a native hover tooltip instead of
## being crammed onto a tiny card.
func _make_relic_widget(artifact: Artifact) -> Button:
	var cost: int = ARTIFACT_COST_BY_RARITY.get(artifact.rarity, 60)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(68, 68)
	btn.icon = IconGenerator.make_icon(artifact.icon_kind, artifact.rarity_color(), 40)
	btn.expand_icon = true
	btn.tooltip_text = "%s (%s)\n%s\n\nCost: %d Star Shards" % [
		artifact.artifact_name, artifact.rarity_name(), artifact.description, cost
	]
	btn.pressed.connect(func():
		if btn.disabled:
			return
		if PlayerStats.spend_star_shards(cost):
			PlayerStats.add_artifact(artifact)
			btn.disabled = true
			btn.modulate = Color(0.55, 0.55, 0.55)
			btn.tooltip_text += "\n(Bought!)"
			_refresh_shard_label()
	)
	return btn

func _make_potion_widget(item: Consumable) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(68, 68)
	btn.icon = IconGenerator.make_icon(item.icon_kind, item.color, 40)
	btn.expand_icon = true
	btn.tooltip_text = "%s\n%s\n\nCost: %d Star Shards" % [item.consumable_name, item.description, item.cost]
	btn.pressed.connect(func():
		if btn.disabled:
			return
		if PlayerStats.spend_star_shards(item.cost):
			PlayerStats.add_consumable(item)
			btn.disabled = true
			btn.modulate = Color(0.55, 0.55, 0.55)
			btn.tooltip_text += "\n(Bought!)"
			_refresh_shard_label()
	)
	return btn

func _make_manage_arcana_widget() -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(68, 68)
	btn.icon = IconGenerator.make_icon("card_major", Color(0.8, 0.35, 0.3), 40)
	btn.expand_icon = true
	btn.tooltip_text = "Manage Arcana\nFuse two equipped cards that share a theme into one stronger card, or remove a card to free its slot."
	btn.pressed.connect(_show_manage_view)
	return btn

# ------------------------------------------------------------ MANAGE ARCANA

func _show_manage_view() -> void:
	_clear(content_area)

	var title := Label.new()
	title.text = "Manage Arcana -- Fuse (%d) matching themes, Remove (%d) to free a slot" % [FUSE_COST, REMOVE_COST]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	content_area.add_child(title)

	var list := VBoxContainer.new()
	content_area.add_child(list)
	for i in range(PlayerStats.equipped_arcana.size()):
		var card: ArcanaCard = PlayerStats.equipped_arcana[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var label := Label.new()
		label.text = "Slot %d: %s" % [i + 1, (card.card_name + " [" + card.theme + "]") if card != null else "(empty)"]
		label.custom_minimum_size = Vector2(320, 0)
		row.add_child(label)
		if card != null:
			var remove_btn := Button.new()
			remove_btn.text = "Remove (%d)" % REMOVE_COST
			remove_btn.pressed.connect(_do_remove.bind(i))
			row.add_child(remove_btn)
			for j in range(PlayerStats.equipped_arcana.size()):
				var other: ArcanaCard = PlayerStats.equipped_arcana[j]
				if j != i and other != null and other.theme == card.theme:
					var fuse_btn := Button.new()
					fuse_btn.text = "Fuse w/ Slot %d (%d)" % [j + 1, FUSE_COST]
					fuse_btn.pressed.connect(_do_fuse.bind(i, j))
					row.add_child(fuse_btn)
					break
		list.add_child(row)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.pressed.connect(_show_main_view)
	content_area.add_child(back_btn)

func _do_remove(slot_index: int) -> void:
	if PlayerStats.spend_star_shards(REMOVE_COST):
		PlayerStats.remove_arcana(slot_index)
		_refresh_shard_label()
	_show_manage_view()

func _do_fuse(slot_a: int, slot_b: int) -> void:
	if PlayerStats.spend_star_shards(FUSE_COST):
		PlayerStats.fuse_arcana(slot_a, slot_b)
		_refresh_shard_label()
	_show_manage_view()
