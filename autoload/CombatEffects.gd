extends Node

## Data-driven event rules for Arcana/artifact/consumable effects.
## Add a rule row and (if needed) one reusable action handler rather than
## expanding a match for every individual item. Rules are inert until equipped.
signal effect_triggered(effect_id: String, event_name: String)

const DEFAULT_RULES: Array[Dictionary] = [
	{"id": "burn_on_hit", "event": "attack_hit", "action": "apply_burn", "cooldown": 0.0},
	{"id": "execution_momentum", "event": "enemy_defeated", "action": "kill_damage_buff", "cooldown": 0.35},
	{"id": "frost_echo", "event": "attack_hit", "action": "apply_chill", "cooldown": 0.0}
]

var rules: Array[Dictionary] = []
var _cooldowns: Dictionary = {}

func _ready() -> void:
	rules = DEFAULT_RULES.duplicate(true)
	CombatEvents.event_dispatched.connect(_on_event_dispatched)

func register_rule(rule: Dictionary) -> bool:
	if not rule.has("id") or not rule.has("event") or not rule.has("action"):
		return false
	if str(rule["id"]).is_empty() or str(rule["event"]).is_empty():
		return false
	rules.append(rule.duplicate(true))
	return true

func clear_runtime_state() -> void:
	_cooldowns.clear()

func _on_event_dispatched(event_name: String, context: Dictionary) -> void:
	for rule in rules:
		if str(rule.get("event", "")) != event_name:
			continue
		if (bool(context.get("is_secondary", false)) or bool(context.get("is_dot", false))) and not bool(rule.get("allow_secondary", false)):
			continue
		var effect_id := str(rule.get("id", ""))
		if not PlayerStats.has_effect(effect_id):
			continue
		if not CombatEvents.claim_effect(effect_id):
			continue
		var cooldown_key := effect_id
		var now := Time.get_ticks_msec() / 1000.0
		if float(_cooldowns.get(cooldown_key, -1.0)) > now:
			continue
		_cooldowns[cooldown_key] = now + maxf(0.0, float(rule.get("cooldown", 0.0)))
		_run_action(str(rule["action"]), rule, context, effect_id)
		effect_triggered.emit(effect_id, event_name)

func _run_action(action: String, rule: Dictionary, context: Dictionary, effect_id: String) -> void:
	var target = context.get("target")
	match action:
		"apply_burn":
			if is_instance_valid(target) and target.has_method("apply_burn") and not bool(target.get("is_dead")):
				var base := PlayerStats.burn_on_hit_value()
				target.apply_burn(maxf(0.0, base), float(rule.get("duration", 3.0)), context.get("attacker"), effect_id)
		"apply_chill":
			if is_instance_valid(target) and target.has_method("apply_chill") and not bool(target.get("is_dead")):
				target.apply_chill(float(rule.get("duration", 2.0)), context.get("attacker"), effect_id)
		"kill_damage_buff":
			var buff := float(rule.get("value", 8.0))
			var duration := float(rule.get("duration", 3.0))
			PlayerStats.temp_dmg_pct = maxf(PlayerStats.temp_dmg_pct, buff)
			PlayerStats.temp_dmg_timer = maxf(PlayerStats.temp_dmg_timer, duration)
