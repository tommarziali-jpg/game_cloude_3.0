extends Node

## Central input binding manager. Keyboard/mouse and controller bindings are
## stored separately so the controller page can remap sticks, buttons and
## triggers without breaking the keyboard setup.

const CONFIG_PATH := "user://input_settings.cfg"

const KEYBOARD_ACTIONS := [
	"move_up", "move_down", "move_left", "move_right",
	"dash", "attack_primary", "attack_secondary",
	"use_ability", "use_consumable", "interact",
]

const CONTROLLER_ACTIONS := [
	"controller_move_up", "controller_move_down", "controller_move_left", "controller_move_right",
	"controller_aim_up", "controller_aim_down", "controller_aim_left", "controller_aim_right",
	"controller_forward", "controller_backward",
	"controller_dash", "controller_attack_primary", "controller_attack_secondary",
	"controller_use_ability", "controller_use_consumable", "controller_interact",
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
	"controller_forward": "Forward",
	"controller_backward": "Backward",
	"controller_dash": "Dash",
	"controller_attack_primary": "Attack (Melee)",
	"controller_attack_secondary": "Attack (Ranged)",
	"controller_use_ability": "Use Ability",
	"controller_use_consumable": "Use Consumable",
	"controller_interact": "Interact",
}

func _ready() -> void:
	load_bindings()

func label_for_action(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "Unbound"
	return label_for_event(events[0])

func label_for_event(event: InputEvent) -> String:
	if event is InputEventKey:
		return OS.get_keycode_string(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
	if event is InputEventJoypadButton:
		match event.button_index:
			JOY_BUTTON_A: return "A"
			JOY_BUTTON_B: return "B"
			JOY_BUTTON_X: return "X"
			JOY_BUTTON_Y: return "Y"
			JOY_BUTTON_LEFT_SHOULDER: return "LB"
			JOY_BUTTON_RIGHT_SHOULDER: return "RB"
			JOY_BUTTON_BACK: return "Back"
			JOY_BUTTON_START: return "Start"
			JOY_BUTTON_LEFT_STICK: return "L3"
			JOY_BUTTON_RIGHT_STICK: return "R3"
			_: return "Controller Button %d" % event.button_index
	if event is InputEventJoypadMotion:
		match event.axis:
			JOY_AXIS_TRIGGER_LEFT: return "LT"
			JOY_AXIS_TRIGGER_RIGHT: return "RT"
			JOY_AXIS_LEFT_X: return "Left Stick X"
			JOY_AXIS_LEFT_Y: return "Left Stick Y"
			JOY_AXIS_RIGHT_X: return "Right Stick X"
			JOY_AXIS_RIGHT_Y: return "Right Stick Y"
			_: return "Controller Axis %d" % event.axis
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: return "Mouse Left"
			MOUSE_BUTTON_RIGHT: return "Mouse Right"
			MOUSE_BUTTON_MIDDLE: return "Mouse Middle"
			_: return "Mouse %d" % event.button_index
	return "?"

func rebind_action(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		return
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	save_bindings()

func set_controller_stick_pair(move_left: bool, aim_right: bool) -> void:
	var move_x := JOY_AXIS_LEFT_X if move_left else JOY_AXIS_RIGHT_X
	var move_y := JOY_AXIS_LEFT_Y if move_left else JOY_AXIS_RIGHT_Y
	var aim_x := JOY_AXIS_RIGHT_X if aim_right else JOY_AXIS_LEFT_X
	var aim_y := JOY_AXIS_RIGHT_Y if aim_right else JOY_AXIS_LEFT_Y
	_set_axis_action("controller_move_left", move_x, -1.0)
	_set_axis_action("controller_move_right", move_x, 1.0)
	_set_axis_action("controller_move_up", move_y, -1.0)
	_set_axis_action("controller_move_down", move_y, 1.0)
	_set_axis_action("controller_aim_left", aim_x, -1.0)
	_set_axis_action("controller_aim_right", aim_x, 1.0)
	_set_axis_action("controller_aim_up", aim_y, -1.0)
	_set_axis_action("controller_aim_down", aim_y, 1.0)
	save_bindings()

func _set_axis_action(action: String, axis: JoyAxis, value: float) -> void:
	InputMap.action_erase_events(action)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)

func reset_controller_defaults() -> void:
	for action in CONTROLLER_ACTIONS:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
	set_controller_stick_pair(true, true)
	_set_axis_action("controller_forward", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_set_axis_action("controller_backward", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_set_button_action("controller_dash", JOY_BUTTON_A)
	_set_button_action("controller_attack_primary", JOY_BUTTON_X)
	_set_button_action("controller_attack_secondary", JOY_BUTTON_B)
	_set_button_action("controller_use_ability", JOY_BUTTON_Y)
	_set_button_action("controller_use_consumable", JOY_BUTTON_LEFT_SHOULDER)
	_set_button_action("controller_interact", JOY_BUTTON_RIGHT_SHOULDER)
	save_bindings()

func _set_button_action(action: String, button: JoyButton) -> void:
	InputMap.action_erase_events(action)
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)

func save_bindings() -> void:
	var cfg := ConfigFile.new()
	for action in KEYBOARD_ACTIONS + CONTROLLER_ACTIONS:
		var events := InputMap.action_get_events(action)
		if events.is_empty():
			continue
		var e: InputEvent = events[0]
		if e is InputEventKey:
			cfg.set_value("bindings", action, {"type": "key", "code": e.physical_keycode if e.physical_keycode != 0 else e.keycode})
		elif e is InputEventMouseButton:
			cfg.set_value("bindings", action, {"type": "mouse", "code": e.button_index})
		elif e is InputEventJoypadButton:
			cfg.set_value("bindings", action, {"type": "joy_button", "code": e.button_index})
		elif e is InputEventJoypadMotion:
			cfg.set_value("bindings", action, {"type": "joy_motion", "axis": e.axis, "value": e.axis_value})
	cfg.save(CONFIG_PATH)

func load_bindings() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	for action in KEYBOARD_ACTIONS + CONTROLLER_ACTIONS:
		if not cfg.has_section_key("bindings", action):
			continue
		var data = cfg.get_value("bindings", action)
		if typeof(data) != TYPE_DICTIONARY:
			continue
		var event: InputEvent = null
		match data.get("type", ""):
			"key":
				var ek := InputEventKey.new()
				ek.physical_keycode = int(data.get("code", 0))
				event = ek
			"mouse":
				var em := InputEventMouseButton.new()
				em.button_index = int(data.get("code", 1))
				event = em
			"joy_button":
				var ejb := InputEventJoypadButton.new()
				ejb.button_index = int(data.get("code", 0))
				event = ejb
			"joy_motion":
				var ejm := InputEventJoypadMotion.new()
				ejm.axis = int(data.get("axis", 0))
				ejm.axis_value = float(data.get("value", 1.0))
				event = ejm
		if event != null and InputMap.has_action(action):
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, event)

func reset_to_defaults() -> void:
	if FileAccess.file_exists(CONFIG_PATH):
		DirAccess.remove_absolute(CONFIG_PATH)
	get_tree().reload_current_scene()
