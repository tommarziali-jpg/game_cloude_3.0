extends Node2D

## The safe zone outside the Spire. Player respawns here on death (or starts
## here fresh). Step into the TowerEntrance to descend -- shopping happens
## inside the tower via the single Shop that opens on every cleared floor,
## spending Star Shards found during the run.

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const HUB_RADIUS := 520.0

@onready var spawn_point: Marker2D = $SpawnPoint

var player: Player = null

func _ready() -> void:
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = spawn_point.global_position if spawn_point else Vector2.ZERO

func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	if player.global_position.length() > HUB_RADIUS:
		player.global_position = player.global_position.normalized() * HUB_RADIUS
