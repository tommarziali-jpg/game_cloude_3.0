extends CanvasLayer

@onready var deepest_label: Label = $Control/TopLeft/DeepestLabel
@onready var runs_label: Label = $Control/TopLeft/RunsLabel
@onready var bosses_label: Label = $Control/TopLeft/BossesLabel
@onready var tier_label: Label = $Control/TopLeft/TierLabel
@onready var flavor_label: Label = $Control/BottomCenter/FlavorLabel

func _ready() -> void:
	_refresh()

func _process(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	deepest_label.text = "Deepest Floor Reached: %d" % PlayerStats.deepest_floor_reached
	runs_label.text = "Descents Attempted: %d" % PlayerStats.total_runs
	bosses_label.text = "Bosses Defeated (all-time): %d" % PlayerStats.bosses_defeated_ever
	tier_label.text = "Unlocked Card Tier: %d" % PlayerStats.unlocked_card_tier
