extends Resource
class_name ArcanaCard

## The core progression unit. Cards go into one of the player's Arcana slots
## (3 at run start, +1 per boss defeated) and modify abilities, stats,
## enemies, hazards, or tower rules for the rest of the run. Matching
## `theme` across equipped cards grants synergy bonuses (see ArcanaEffects).
## Major Arcana are run-defining legendaries; some of them are "active" --
## they bind to the Ability key instead of applying a passive effect.

enum ArcanaType { MINOR, MAJOR, CORRUPTED, ASTRAL }

@export var card_name: String = "Unnamed Arcana"
@export var description: String = ""
@export var arcana_type: ArcanaType = ArcanaType.MINOR
@export var theme: String = "Neutral"          ## "Fire", "Storm", "Frost", "Shadow", "Nature", "Void", "Blood", "Neutral"
@export var effect_id: String = ""              ## key consumed by ArcanaEffects.gd
@export var value: float = 0.0                  ## base magnitude of the effect
@export var icon_kind: String = "card_minor"     ## key consumed by IconGenerator
@export var is_active_ability: bool = false      ## true = binds to the Ability key instead of passive
@export var ability_cooldown: float = 8.0        ## only used if is_active_ability
@export var level: int = 1                       ## 2+ once fused with a matching-theme card

func type_name() -> String:
	match arcana_type:
		ArcanaType.MINOR: return "Minor Arcana"
		ArcanaType.MAJOR: return "Major Arcana"
		ArcanaType.CORRUPTED: return "Corrupted Arcana"
		ArcanaType.ASTRAL: return "Astral Arcana"
	return "?"

func type_color() -> Color:
	match arcana_type:
		ArcanaType.MINOR: return Color(0.6, 0.75, 1.0)
		ArcanaType.MAJOR: return Color(1.0, 0.75, 0.2)
		ArcanaType.CORRUPTED: return Color(0.75, 0.15, 0.25)
		ArcanaType.ASTRAL: return Color(0.65, 0.35, 1.0)
	return Color.WHITE

func theme_color() -> Color:
	match theme:
		"Fire": return Color(0.95, 0.45, 0.1)
		"Storm": return Color(0.3, 0.75, 0.95)
		"Frost": return Color(0.55, 0.85, 0.95)
		"Shadow": return Color(0.4, 0.2, 0.55)
		"Nature": return Color(0.35, 0.8, 0.4)
		"Void": return Color(0.55, 0.1, 0.65)
		"Blood": return Color(0.7, 0.1, 0.15)
	return Color(0.7, 0.7, 0.7)

## A displayable value string, e.g. "+15% Damage" -- used by card UI.
func value_text() -> String:
	return "%s%.0f" % ["+" if value >= 0 else "", value]

## Produces an upgraded/fused copy (used when two matching-theme cards fuse).
func make_fused_copy() -> ArcanaCard:
	var c: ArcanaCard = self.duplicate(true)
	c.level += 1
	c.value *= 1.6
	c.card_name = "Fused " + card_name
	return c
