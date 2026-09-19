extends Resource
class_name Artifact

## Permanent (for the rest of the run) passive item. Found in Artifact Rooms,
## boss chests, and rare shop slots. Unlike Arcana Cards, Artifacts don't take
## up a slot -- you keep every one you find for the whole run.

enum Rarity { COMMON, RARE, LEGENDARY }

@export var artifact_name: String = "Unnamed Artifact"
@export var description: String = ""
@export var effect_id: String = ""
@export var value: float = 0.0
@export var rarity: Rarity = Rarity.COMMON
@export var icon_kind: String = "artifact_common"

func rarity_name() -> String:
	match rarity:
		Rarity.COMMON: return "Common"
		Rarity.RARE: return "Rare"
		Rarity.LEGENDARY: return "Legendary"
	return "?"

func rarity_color() -> Color:
	match rarity:
		Rarity.COMMON: return Color(0.75, 0.75, 0.75)
		Rarity.RARE: return Color(0.3, 0.55, 1.0)
		Rarity.LEGENDARY: return Color(1.0, 0.65, 0.15)
	return Color.WHITE
