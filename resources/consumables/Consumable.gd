extends Resource
class_name Consumable

## One-time item used by pressing the Consumable key. Found in chests/reward
## altars, shops (Rest Chambers / Special Shops), and mob drops. Stacks in
## inventory; using one consumes exactly one copy.

enum ConsumableEffect { HEAL, STRENGTH_BUFF, SPEED_BUFF, FORTITUDE_BUFF, SHARD_BURST, SHIELD }

@export var consumable_name: String = "Consumable"
@export var description: String = ""
@export var effect: ConsumableEffect = ConsumableEffect.HEAL
@export var value: float = 0.0
@export var duration: float = 0.0   ## seconds; 0 for instant effects
@export var cost: int = 10          ## Star Shard price in shops
@export var icon_kind: String = "potion_heal"
@export var color: Color = Color(1, 1, 1)
