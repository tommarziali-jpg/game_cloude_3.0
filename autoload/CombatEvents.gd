extends Node

## Shared, typed combat/progression event surface for item effects.
## Gameplay systems emit facts; item systems can subscribe without hard-coded
## references between every card, artifact, consumable, and combat actor.

signal player_attack_started(attacker: Node, attack_kind: String)
signal enemy_damaged(target: Node, amount: float, source: Node, is_dot: bool)
signal enemy_defeated(target: Node, source: Node)
signal player_damaged(amount: float, source: Node)
signal consumable_used(item: Consumable, item_id: String)
signal floor_started(floor_number: int, is_boss_floor: bool)
signal floor_cleared(floor_number: int)
