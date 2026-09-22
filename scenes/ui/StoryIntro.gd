extends Control

## The very first thing the player sees. Shows the SOULFALL backstory, then
## continues to the Main Menu on a key press / button click / after a while.

const STORY_TEXT := "Long before your name meant anything, there was a hole in the world.

The old maps called it the Hollow Spire — a black tower rising out of a crater where a kingdom used to be. The priests who built it swore it was not a tower at all, but a stopper. A cork driven into a wound that opens straight down into Hell.

For a thousand years, the cork held. Then, six months ago, it didn't.

The Spire folded in on itself, floor after floor spiraling down into the dark, and it took your home with it — Ashcombe, gone in a single night, swallowed whole. Everyone you have ever loved is down there now, dissolving slowly into the Spire's hunger, becoming fuel for a seal that was never supposed to fail.

You carry the old blood — the blood of the Wardens who built the seal in the first place. It is the only reason the Spire spits you back out instead of keeping you, floor after floor, fall after fall.

So you go down. Not because you are brave. Because you are the only one who can survive trying.

Somewhere below, past a hundred floors of everything Hell has ever built from cruelty and grief, your people are waiting. And past them — if the old texts are true — sits the thing that opened this hole in the first place. Still hungry. Still waiting for someone strong enough to either feed it forever, or shut it for good."

@onready var story_label: Label = $CenterContainer/VBox/ScrollContainer/StoryLabel
@onready var continue_label: Label = $CenterContainer/VBox/ContinueLabel
@onready var skip_button: Button = $SkipButton

var can_continue: bool = false

func _ready() -> void:
	story_label.text = STORY_TEXT
	story_label.modulate.a = 0.0
	continue_label.modulate.a = 0.0
	skip_button.pressed.connect(_go_to_menu)

	var tween := create_tween()
	tween.tween_property(story_label, "modulate:a", 1.0, 2.0)
	tween.tween_callback(_enable_continue)

func _enable_continue() -> void:
	can_continue = true
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(continue_label, "modulate:a", 1.0, 0.8)
	tween.tween_property(continue_label, "modulate:a", 0.3, 0.8)

func _unhandled_input(event: InputEvent) -> void:
	if not can_continue:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_go_to_menu()
	elif event is InputEventMouseButton and event.pressed:
		_go_to_menu()
	elif event is InputEventJoypadButton and event.pressed:
		# A is the normal controller "accept" button. Start/B are also useful
		# here so the intro can always be skipped without a keyboard.
		if event.button_index == JOY_BUTTON_A or event.button_index == JOY_BUTTON_B or event.button_index == JOY_BUTTON_START:
			_go_to_menu()

func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
