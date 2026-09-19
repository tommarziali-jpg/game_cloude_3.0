extends Area2D
class_name FloorPortal

## Replaces the old auto-descend countdown timer. Spawned alongside the Shop
## once a floor is cleared; the player must walk up and press "interact" to
## step through it and descend to the next floor -- no more automatic timer.

signal entered

@onready var prompt_label: Label = $PromptLabel
@onready var swirl: Polygon2D = $Visual/Swirl

var player_inside: bool = false
var used: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt_label.visible = false

func _process(delta: float) -> void:
	if swirl:
		swirl.rotation += delta * 1.4
	if player_inside and not used and Input.is_action_just_pressed("interact"):
		_enter()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = true
		if not used:
			prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false
		prompt_label.visible = false

func _enter() -> void:
	if used:
		return
	used = true
	prompt_label.visible = false
	entered.emit()
