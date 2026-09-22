extends Control

@onready var list_vbox: VBoxContainer = $Panel/VBox/ScrollContainer/List
@onready var back_button: Button = $Panel/VBox/BackButton
@onready var controller_button: Button = $Panel/VBox/ControllerSettingsButton
@onready var listening_label: Label = $Panel/VBox/ListeningLabel

var listening_for_action := ""
var action_buttons: Dictionary = {}

func _ready() -> void:
	back_button.pressed.connect(_on_back)
	controller_button.pressed.connect(_on_controller_settings)
	listening_label.visible = false
	_build_keyboard_rows()

func _build_keyboard_rows() -> void:
	for action in SettingsManager.KEYBOARD_ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var label := Label.new()
		label.text = SettingsManager.DISPLAY_NAMES.get(action, action)
		label.custom_minimum_size = Vector2(220, 0)
		row.add_child(label)
		var button := Button.new()
		button.text = SettingsManager.label_for_action(action)
		button.custom_minimum_size = Vector2(180, 0)
		button.pressed.connect(_on_rebind_pressed.bind(action, button))
		row.add_child(button)
		list_vbox.add_child(row)
		action_buttons[action] = button

func _on_rebind_pressed(action: String, button: Button) -> void:
	listening_for_action = action
	button.text = "Press key/button..."
	listening_label.visible = true
	listening_label.text = "Press a new input for %s (Esc to cancel)" % SettingsManager.DISPLAY_NAMES.get(action, action)


func _unhandled_input(event: InputEvent) -> void:
	if listening_for_action == "":
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
			_on_back()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_cancel_listen()
			get_viewport().set_input_as_handled()
			return
		SettingsManager.rebind_action(listening_for_action, event)
		_finish_listen()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		SettingsManager.rebind_action(listening_for_action, event)
		_finish_listen()
		get_viewport().set_input_as_handled()

func _cancel_listen() -> void:
	var button: Button = action_buttons.get(listening_for_action)
	if button:
		button.text = SettingsManager.label_for_action(listening_for_action)
	listening_for_action = ""
	listening_label.visible = false

func _finish_listen() -> void:
	var button: Button = action_buttons.get(listening_for_action)
	if button:
		button.text = SettingsManager.label_for_action(listening_for_action)
	listening_for_action = ""
	listening_label.visible = false

func _on_controller_settings() -> void:
	var ancestor: Node = get_parent()
	while ancestor != null:
		if ancestor.has_method("_open_controller_settings_overlay"):
			ancestor._open_controller_settings_overlay()
			return
		ancestor = ancestor.get_parent()
	get_tree().change_scene_to_file("res://scenes/ui/ControllerSettings.tscn")

func _open_controller_settings_overlay() -> void:
	# This method is used when Settings itself is already the overlay.
	if get_node_or_null("ControllerSettingsOverlay") != null:
		return
	hide()
	var controller_scene := preload("res://scenes/ui/ControllerSettings.tscn").instantiate()
	controller_scene.name = "ControllerSettingsOverlay"
	add_child(controller_scene)

func _close_controller_settings_overlay() -> void:
	var controller_scene := get_node_or_null("ControllerSettingsOverlay")
	if controller_scene != null:
		controller_scene.queue_free()
	show()
	controller_button.grab_focus()

func _on_back() -> void:
	var ancestor: Node = get_parent()
	while ancestor != null:
		if ancestor.has_method("_close_settings_overlay"):
			ancestor._close_settings_overlay(self)
			return
		ancestor = ancestor.get_parent()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
