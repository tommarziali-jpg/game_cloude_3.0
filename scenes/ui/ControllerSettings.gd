extends Control

@onready var list_vbox: VBoxContainer = $Panel/Content/Left/Scroll/List
@onready var listening_label: Label = $Panel/Content/ListeningLabel
@onready var move_stick_button: Button = $Panel/Content/Left/StickGrid/MoveStickButton
@onready var aim_stick_button: Button = $Panel/Content/Left/StickGrid/AimStickButton

var listening_for_action := ""
var action_buttons: Dictionary = {}
var move_uses_left := true
var aim_uses_right := true

const CONTROLLER_ROWS := [
	["controller_forward", "Forward"],
	["controller_backward", "Backward"],
	["controller_dash", "Dash"],
	["controller_attack_primary", "Attack (Melee)"],
	["controller_attack_secondary", "Attack (Ranged)"],
	["controller_use_ability", "Ability"],
	["controller_use_consumable", "Consumable"],
	["controller_interact", "Interact"],
]

func _ready() -> void:
	$Panel/Content/TopBar/CloseButton.pressed.connect(_on_back)
	$Panel/Content/Left/ResetButton.pressed.connect(_on_reset)
	move_stick_button.pressed.connect(_toggle_move_stick)
	aim_stick_button.pressed.connect(_toggle_aim_stick)
	_build_rows()
	_update_stick_labels()
	listening_label.visible = false

func _build_rows() -> void:
	for data in CONTROLLER_ROWS:
		var action: String = data[0]
		var display_name: String = data[1]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)

		var label := Label.new()
		label.text = display_name
		label.custom_minimum_size = Vector2(235, 0)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)

		var button := Button.new()
		button.text = SettingsManager.label_for_action(action)
		button.custom_minimum_size = Vector2(190, 38)
		button.pressed.connect(_start_rebind.bind(action, button))
		row.add_child(button)
		action_buttons[action] = button
		list_vbox.add_child(row)

func _start_rebind(action: String, button: Button) -> void:
	listening_for_action = action
	button.text = "Press button / trigger..."
	listening_label.visible = true
	listening_label.text = "Press the controller input for "%s" — Esc cancels" % SettingsManager.DISPLAY_NAMES.get(action, action)

func _unhandled_input(event: InputEvent) -> void:
	if listening_for_action == "":
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_cancel_rebind()
		else:
			_finish_rebind(event)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventJoypadButton and event.pressed:
		_finish_rebind(event)
		get_viewport().set_input_as_handled()
		return

	# Triggers are analog axes in Godot. Only accept LT/RT axes here so
	# moving a stick cannot accidentally become a button binding.
	if event is InputEventJoypadMotion and abs(event.axis_value) >= 0.65:
		if event.axis == JOY_AXIS_TRIGGER_LEFT or event.axis == JOY_AXIS_TRIGGER_RIGHT:
			var trigger := InputEventJoypadMotion.new()
			trigger.axis = event.axis
			trigger.axis_value = 1.0
			_finish_rebind(trigger)
			get_viewport().set_input_as_handled()

func _finish_rebind(event: InputEvent) -> void:
	SettingsManager.rebind_action(listening_for_action, event)
	var button: Button = action_buttons.get(listening_for_action)
	if button:
		button.text = SettingsManager.label_for_action(listening_for_action)
	listening_for_action = ""
	listening_label.visible = false

func _cancel_rebind() -> void:
	var button: Button = action_buttons.get(listening_for_action)
	if button:
		button.text = SettingsManager.label_for_action(listening_for_action)
	listening_for_action = ""
	listening_label.visible = false

func _toggle_move_stick() -> void:
	move_uses_left = not move_uses_left
	_apply_sticks()

func _toggle_aim_stick() -> void:
	aim_uses_right = not aim_uses_right
	_apply_sticks()

func _apply_sticks() -> void:
	SettingsManager.set_controller_stick_pair(move_uses_left, aim_uses_right)
	_update_stick_labels()

func _update_stick_labels() -> void:
	move_stick_button.text = "Left Stick" if move_uses_left else "Right Stick"
	aim_stick_button.text = "Right Stick" if aim_uses_right else "Left Stick"

func _on_reset() -> void:
	SettingsManager.reset_controller_defaults()
	move_uses_left = true
	aim_uses_right = true
	_update_stick_labels()
	for action in action_buttons:
		action_buttons[action].text = SettingsManager.label_for_action(action)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/Settings.tscn")
