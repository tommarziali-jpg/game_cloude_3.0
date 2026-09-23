extends Control

@onready var pause_panel: PanelContainer = $PausePanel
@onready var resume_button: Button = $PausePanel/VBox/ResumeButton
@onready var settings_button: Button = $PausePanel/VBox/SettingsButton
@onready var main_menu_button: Button = $PausePanel/VBox/MainMenuButton
@onready var quit_button: Button = $PausePanel/VBox/QuitButton
@onready var settings_layer: Control = $SettingsLayer

@onready var settings_overlay: Control = $SettingsLayer/Settings

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(_resume)
	settings_button.pressed.connect(_open_settings)
	main_menu_button.pressed.connect(_go_to_main_menu)
	quit_button.pressed.connect(_quit_game)

func _unhandled_input(event: InputEvent) -> void:
	if settings_overlay != null:
		return

	var toggle := false
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		toggle = true
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		toggle = true

	if toggle:
		if get_tree().paused:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()

func _pause() -> void:
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()
	pause_panel.show()
	resume_button.grab_focus()

func _resume() -> void:
	settings_overlay = null
	settings_layer.hide()
	pause_panel.show()
	hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _open_settings() -> void:
	pause_panel.hide()
	settings_layer.show()
	settings_overlay.show()
	settings_overlay.controller_button.grab_focus()

func _close_settings_overlay(settings: Control) -> void:
	settings_overlay.hide()
	settings_layer.hide()
	pause_panel.show()
	settings_button.grab_focus()

func _go_to_main_menu() -> void:
	get_tree().paused = false
	GameManager.run_active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()
