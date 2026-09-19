extends Area2D
class_name TowerEntrance

## The maw of the Hollow Spire. Press "interact" while standing in it to
## begin a fresh descent from Floor 1.

@onready var prompt_label: Label = $PromptLabel
var player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt_label.visible = false

func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		GameManager.enter_tower()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = true
		prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false
		prompt_label.visible = false
