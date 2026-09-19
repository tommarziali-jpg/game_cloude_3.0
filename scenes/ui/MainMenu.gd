extends Control

@onready var start_button: Button = $CenterContainer/VBox/StartButton
@onready var settings_button: Button = $CenterContainer/VBox/SettingsButton
@onready var quit_button: Button = $CenterContainer/VBox/QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)
	start_button.grab_focus()

func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/Hub.tscn")

func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/Settings.tscn")

func _on_quit() -> void:
	get_tree().quit()
