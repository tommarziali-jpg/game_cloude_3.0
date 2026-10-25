extends Node

## Ordered combat event queue. Gameplay publishes facts; listeners consume them
## in FIFO order on the next process tick, never recursively on the damage stack.
## Child effects inherit a chain id/depth and a per-chain effect-visit set.
signal event_dispatched(event_name: String, context: Dictionary)
signal player_attack_started(attacker: Node, attack_kind: String)
signal attack_hit(context: Dictionary)
signal critical_hit(context: Dictionary)
signal enemy_damaged(target: Node, amount: float, source: Node, is_dot: bool)
signal enemy_defeated(target: Node, source: Node)
signal player_damaged(amount: float, source: Node)
signal dash_started(player: Node, direction: Vector2)
signal successful_dodge(player: Node, attacker: Node)
signal ability_activated(player: Node, ability_id: String)
signal status_applied(target: Node, status_id: String, source: Node)
signal status_expired(target: Node, status_id: String)
signal consumable_used(item: Consumable, item_id: String)
signal floor_started(floor_number: int, is_boss_floor: bool)
signal floor_cleared(floor_number: int)
signal wave_cleared(wave_number: int)
signal boss_phase_changed(boss: Node, phase: int)
signal boss_defeated(boss: Node)

const MAX_CHAIN_DEPTH := 8
const MAX_EVENTS_PER_CHAIN := 32
const MAX_DISPATCH_PER_FRAME := 256

var _queue: Array[Dictionary] = []
var _next_event_id: int = 1
var _next_chain_id: int = 1
var _active_context: Dictionary = {}
var _chain_event_counts: Dictionary = {}
var _recent_duplicate_keys: Dictionary = {}

func _process(_delta: float) -> void:
	var dispatched := 0
	while not _queue.is_empty() and dispatched < MAX_DISPATCH_PER_FRAME:
		var event: Dictionary = _queue.pop_front()
		_dispatch(event)
		dispatched += 1
	_prune_chain_counts()

## Context should include attacker/target/source/effect_id when relevant.
func publish(event_name: String, context: Dictionary = {}) -> bool:
	if event_name.is_empty():
		return false
	var payload := context.duplicate()
	var depth := int(_active_context.get("_chain_depth", -1)) + 1 if not _active_context.is_empty() else 0
	var chain_id := int(_active_context.get("_chain_id", 0)) if not _active_context.is_empty() else 0
	var visited: Dictionary = _active_context.get("_visited_effects", {}).duplicate() if not _active_context.is_empty() else {}
	if depth > MAX_CHAIN_DEPTH:
		return false
	if chain_id == 0:
		chain_id = _next_chain_id
		_next_chain_id += 1
		_chain_event_counts[chain_id] = 0
	var count := int(_chain_event_counts.get(chain_id, 0))
	if count >= MAX_EVENTS_PER_CHAIN:
		return false
	_chain_event_counts[chain_id] = count + 1
	payload["_event_id"] = _next_event_id
	_next_event_id += 1
	payload["_chain_id"] = chain_id
	payload["_chain_depth"] = depth
	payload["_visited_effects"] = visited
	payload["_event_name"] = event_name
	_queue.append({"name": event_name, "context": payload})
	return true

## Prevents the same effect from firing twice in a single causal chain.
func claim_effect(effect_id: String) -> bool:
	if effect_id.is_empty():
		return false
	if _active_context.is_empty():
		return true
	var visited: Dictionary = _active_context.get("_visited_effects", {})
	if visited.has(effect_id):
		return false
	visited[effect_id] = true
	_active_context["_visited_effects"] = visited
	return true

## Collision/callback dedupe with an optional cooldown (seconds).
func publish_once(key: String, cooldown_seconds: float, event_name: String, context: Dictionary = {}) -> bool:
	if key.is_empty():
		return publish(event_name, context)
	var now := Time.get_ticks_msec() / 1000.0
	if float(_recent_duplicate_keys.get(key, -1.0)) > now:
		return false
	_recent_duplicate_keys[key] = now + maxf(0.0, cooldown_seconds)
	return publish(event_name, context)

func reset_for_new_run() -> void:
	_queue.clear()
	_chain_event_counts.clear()
	_recent_duplicate_keys.clear()
	_active_context.clear()

func _dispatch(event: Dictionary) -> void:
	var name: String = event["name"]
	var context: Dictionary = event["context"]
	_active_context = context
	for key in ["attacker", "target", "source", "player", "boss"]:
		if context.has(key) and context[key] is Node and not is_instance_valid(context[key]):
			context[key] = null
	event_dispatched.emit(name, context)
	match name:
		"player_attack_started":
			player_attack_started.emit(context.get("attacker"), str(context.get("attack_type", "unknown")))
		"attack_hit":
			attack_hit.emit(context)
		"critical_hit":
			critical_hit.emit(context)
		"enemy_damaged":
			enemy_damaged.emit(context.get("target"), float(context.get("damage", 0.0)), context.get("source"), bool(context.get("is_dot", false)))
		"enemy_defeated":
			enemy_defeated.emit(context.get("target"), context.get("source"))
		"player_damaged":
			player_damaged.emit(float(context.get("damage", 0.0)), context.get("source"))
		"dash_started":
			dash_started.emit(context.get("player"), context.get("direction", Vector2.ZERO))
		"successful_dodge":
			successful_dodge.emit(context.get("player"), context.get("attacker"))
		"ability_activated":
			ability_activated.emit(context.get("player"), str(context.get("ability_id", "")))
		"status_applied":
			status_applied.emit(context.get("target"), str(context.get("status_id", "")), context.get("source"))
		"status_expired":
			status_expired.emit(context.get("target"), str(context.get("status_id", "")))
		"consumable_used":
			consumable_used.emit(context.get("item"), str(context.get("item_id", "")))
		"floor_started":
			floor_started.emit(int(context.get("floor_number", 0)), bool(context.get("is_boss_floor", false)))
		"floor_cleared":
			floor_cleared.emit(int(context.get("floor_number", 0)))
		"wave_cleared":
			wave_cleared.emit(int(context.get("wave_number", 0)))
		"boss_phase_changed":
			boss_phase_changed.emit(context.get("boss"), int(context.get("phase", 0)))
		"boss_defeated":
			boss_defeated.emit(context.get("boss"))
	_active_context = {}

func _prune_chain_counts() -> void:
	var active: Dictionary = {}
	for event in _queue:
		active[int(event["context"].get("_chain_id", 0))] = true
	for chain_id in _chain_event_counts.keys():
		if not active.has(chain_id):
			_chain_event_counts.erase(chain_id)
