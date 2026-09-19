extends Control

## Settings screen: lists every rebindable action with its current key and a
## "Rebind" button. Click Rebind, then press any key/mouse button to assign
## it -- rebinding is immediate and saved via SettingsManager.

@onready var list_vbox: VBoxContainer = $Panel/VBox/ScrollContainer/List
@onready var back_button: Button = $Panel/VBox/BackButton
@onready var listening_label: Label = $Panel/VBox/ListeningLabel

var listening_for_action: String = ""
var action_buttons: Dictionary = {}  ## action -> Button (shows current key)

func _ready() -> void:
	back_button.pressed.connect(_on_back)
	listening_label.visible = false
	_build_rows()

func _build_rows() -> void:
	for action in SettingsManager.REBINDABLE_ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)

		var name_label := Label.new()
		name_label.text = SettingsManager.DISPLAY_NAMES.get(action, action)
		name_label.custom_minimum_size = Vector2(200, 0)
		row.add_child(name_label)

		var key_button := Button.new()
		key_button.text = SettingsManager.label_for_action(action)
		key_button.custom_minimum_size = Vector2(140, 0)
		key_button.pressed.connect(_on_rebind_pressed.bind(action, key_button))
		row.add_child(key_button)
		action_buttons[action] = key_button

		list_vbox.add_child(row)

func _on_rebind_pressed(action: String, key_button: Button) -> void:
	listening_for_action = action
	key_button.text = "Press a key..."
	listening_label.visible = true
	listening_label.text = "Listening for a new key for \"%s\" (Esc to cancel)" % SettingsManager.DISPLAY_NAMES.get(action, action)

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
