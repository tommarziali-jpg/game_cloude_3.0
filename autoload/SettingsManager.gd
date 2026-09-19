extends Node

## Handles input rebinding: lets Settings.tscn listen for a key press and
## reassign it to an action, then persists the mapping to
## user://input_settings.cfg so it survives restarts.

const CONFIG_PATH := "user://input_settings.cfg"

const REBINDABLE_ACTIONS := [
	"move_up", "move_down", "move_left", "move_right",
	"dash", "attack_primary", "attack_secondary",
	"use_ability", "use_consumable", "interact",
]

const DISPLAY_NAMES := {
	"move_up": "Move Up",
	"move_down": "Move Down",
	"move_left": "Move Left",
	"move_right": "Move Right",
	"dash": "Dash",
	"attack_primary": "Attack (Melee)",
	"attack_secondary": "Attack (Ranged)",
	"use_ability": "Use Ability",
	"use_consumable": "Use Consumable",
	"interact": "Interact",
}

func _ready() -> void:
	load_bindings()

## Returns a short human-readable label for whatever is currently bound.
func label_for_action(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "Unbound"
	var e: InputEvent = events[0]
	if e is InputEventKey:
		return OS.get_keycode_string(e.physical_keycode if e.physical_keycode != 0 else e.keycode)
	if e is InputEventMouseButton:
		match e.button_index:
			MOUSE_BUTTON_LEFT: return "Mouse Left"
			MOUSE_BUTTON_RIGHT: return "Mouse Right"
			MOUSE_BUTTON_MIDDLE: return "Mouse Middle"
			_: return "Mouse %d" % e.button_index
	return "?"

## Replaces whatever is bound to `action` with the single new event.
func rebind_action(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		return
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	save_bindings()

func reset_to_defaults() -> void:
	if FileAccess.file_exists(CONFIG_PATH):
		DirAccess.remove_absolute(CONFIG_PATH)
	# Actions keep whatever is baked into project.godot until the game restarts;
	# for a prototype this is an acceptable tradeoff (documented in DESIGN.md).

func save_bindings() -> void:
	var cfg := ConfigFile.new()
	for action in REBINDABLE_ACTIONS:
		var events := InputMap.action_get_events(action)
		if events.is_empty():
			continue
		var e: InputEvent = events[0]
		if e is InputEventKey:
			cfg.set_value("bindings", action, {"type": "key", "code": e.physical_keycode if e.physical_keycode != 0 else e.keycode})
		elif e is InputEventMouseButton:
			cfg.set_value("bindings", action, {"type": "mouse", "code": e.button_index})
	cfg.save(CONFIG_PATH)

func load_bindings() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	for action in REBINDABLE_ACTIONS:
		if not cfg.has_section_key("bindings", action):
			continue
		var data = cfg.get_value("bindings", action)
		if typeof(data) != TYPE_DICTIONARY:
			continue
		var event: InputEvent = null
		if data.get("type") == "key":
			var ek := InputEventKey.new()
			ek.physical_keycode = int(data.get("code", 0))
			event = ek
		elif data.get("type") == "mouse":
			var em := InputEventMouseButton.new()
			em.button_index = int(data.get("code", 1))
			event = em
		if event != null and InputMap.has_action(action):
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, event)
