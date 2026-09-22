extends Node

## Handles input rebinding: lets Settings.tscn listen for a key press and
## reassign it to an action, then persists the mapping to
## user://input_settings.cfg so it survives restarts.

const CONFIG_PATH := "user://input_settings.cfg"

const REBINDABLE_ACTIONS := [
	"move_up", "move_down", "move_left", "move_right",
	"dash", "attack_primary", "attack_secondary",
	"use_ability", "use_consumable", "interact",
	"controller_stick",
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
	"controller_stick": "Controller Stick (Move + Aim)",
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
	if e is InputEventJoypadButton:
		return "Controller Button %d" % e.button_index
	if e is InputEventJoypadMotion:
		return "Controller Stick"
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

func get_controller_stick_label() -> String:
	var axis_events := InputMap.action_get_events("controller_left")
	if not axis_events.is_empty():
		var e: InputEvent = axis_events[0]
		if e is InputEventJoypadMotion:
			if e.axis == JOY_AXIS_LEFT_X:
				return "Left Stick"
			if e.axis == JOY_AXIS_RIGHT_X:
				return "Right Stick"
	return "Left Stick"

func set_controller_stick(use_left: bool) -> void:
	var x_axis := JOY_AXIS_LEFT_X if use_left else JOY_AXIS_RIGHT_X
	var y_axis := JOY_AXIS_LEFT_Y if use_left else JOY_AXIS_RIGHT_Y
	_set_stick_action("controller_left", x_axis, -1.0)
	_set_stick_action("controller_right", x_axis, 1.0)
	_set_stick_action("controller_up", y_axis, -1.0)
	_set_stick_action("controller_down", y_axis, 1.0)
	save_bindings()

func _set_stick_action(action: String, axis: JoyAxis, value: float) -> void:
	if not InputMap.has_action(action):
		return
	InputMap.action_erase_events(action)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)

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
		elif data.get("type") == "joy_button":
			var ejb := InputEventJoypadButton.new()
			ejb.button_index = int(data.get("code", 0))
			event = ejb
		elif data.get("type") == "joy_motion":
			var ejm := InputEventJoypadMotion.new()
			ejm.axis = int(data.get("axis", 0))
			ejm.axis_value = float(data.get("value", 0.0))
			event = ejm
		elif data.get("type") == "mouse":
			var em := InputEventMouseButton.new()
			em.button_index = int(data.get("code", 1))
			event = em
		if event != null and InputMap.has_action(action):
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, event)
