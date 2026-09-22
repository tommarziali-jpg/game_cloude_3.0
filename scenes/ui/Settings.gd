extends Control

## Settings screen with separate Keyboard/Mouse and Controller sections.
## Controller: one shared stick controls both movement and aim.

@onready var list_vbox: VBoxContainer = $Panel/VBox/ScrollContainer/List
@onready var controller_vbox: VBoxContainer = $Panel/VBox/ScrollContainer/List/ControllerSection/ControllerList
@onready var back_button: Button = $Panel/VBox/BackButton
@onready var listening_label: Label = $Panel/VBox/ListeningLabel

var listening_for_action: String = ""
var action_buttons: Dictionary = {}

func _ready() -> void:
	back_button.pressed.connect(_on_back)
	listening_label.visible = false
	_build_rows()
	_build_controller_rows()

func _build_rows() -> void:
	for action in SettingsManager.REBINDABLE_ACTIONS:
		if action == "controller_stick" or action in ["dash", "attack_primary", "attack_secondary", "use_ability", "use_consumable", "interact"]:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var name_label := Label.new()
		name_label.text = SettingsManager.DISPLAY_NAMES.get(action, action)
		name_label.custom_minimum_size = Vector2(200, 0)
		row.add_child(name_label)
		var key_button := Button.new()
		key_button.text = SettingsManager.label_for_action(action)
		key_button.custom_minimum_size = Vector2(180, 0)
		key_button.pressed.connect(_on_rebind_pressed.bind(action, key_button))
		row.add_child(key_button)
		action_buttons[action] = key_button
		list_vbox.add_child(row)

func _build_controller_rows() -> void:
	var stick_row := HBoxContainer.new()
	stick_row.add_theme_constant_override("separation", 16)
	var stick_label := Label.new()
	stick_label.text = "Move + Aim Stick"
	stick_label.custom_minimum_size = Vector2(200, 0)
	stick_row.add_child(stick_label)
	var stick_button := Button.new()
	stick_button.text = SettingsManager.get_controller_stick_label()
	stick_button.custom_minimum_size = Vector2(180, 0)
	stick_button.pressed.connect(_toggle_controller_stick)
	stick_row.add_child(stick_button)
	controller_vbox.add_child(stick_row)
	action_buttons["controller_stick"] = stick_button

	for action in ["dash", "attack_primary", "attack_secondary", "use_ability", "use_consumable", "interact"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var label := Label.new()
		label.text = SettingsManager.DISPLAY_NAMES.get(action, action)
		label.custom_minimum_size = Vector2(200, 0)
		row.add_child(label)
		var button := Button.new()
		button.text = SettingsManager.label_for_action(action)
		button.custom_minimum_size = Vector2(180, 0)
		button.pressed.connect(_on_rebind_pressed.bind(action, button))
		row.add_child(button)
		controller_vbox.add_child(row)
		action_buttons[action] = button

func _toggle_controller_stick() -> void:
	var use_left := SettingsManager.get_controller_stick_label() != "Left Stick"
	SettingsManager.set_controller_stick(use_left)
	action_buttons["controller_stick"].text = SettingsManager.get_controller_stick_label()

func _on_rebind_pressed(action: String, key_button: Button) -> void:
	listening_for_action = action
	key_button.text = "Press key/button..."
	listening_label.visible = true
	listening_label.text = "Press a keyboard key or controller button for \"%s\" (Esc to cancel)" % SettingsManager.DISPLAY_NAMES.get(action, action)

func _unhandled_input(event: InputEvent) -> void:
	if listening_for_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_cancel_listen()
			return
		SettingsManager.rebind_action(listening_for_action, event)
		_finish_listen()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		SettingsManager.rebind_action(listening_for_action, event)
		_finish_listen()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		SettingsManager.rebind_action(listening_for_action, event)
		_finish_listen()
		get_viewport().set_input_as_handled()

func _cancel_listen() -> void:
	var btn: Button = action_buttons.get(listening_for_action)
	if btn:
		btn.text = SettingsManager.label_for_action(listening_for_action)
	listening_for_action = ""
	listening_label.visible = false

func _finish_listen() -> void:
	var btn: Button = action_buttons.get(listening_for_action)
	if btn:
		btn.text = SettingsManager.label_for_action(listening_for_action)
	listening_for_action = ""
	listening_label.visible = false

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
