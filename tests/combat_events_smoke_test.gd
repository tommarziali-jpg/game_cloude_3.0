extends SceneTree

## Headless smoke test: godot --headless --path . --script tests/combat_events_smoke_test.gd
var bus
var received: Array[String] = []
var chain_received := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var event_script = load("res://autoload/CombatEvents.gd")
	bus = event_script.new()
	root.add_child(bus)
	bus.event_dispatched.connect(_on_event)
	assert(bus.publish("player_attack_started", {"attack_type": "melee"}))
	await process_frame
	assert(received.size() == 1 and received[0] == "player_attack_started")

	assert(bus.publish_once("smoke:dedupe", 1.0, "attack_hit", {"damage": 5.0}))
	assert(not bus.publish_once("smoke:dedupe", 1.0, "attack_hit", {"damage": 5.0}))
	await process_frame
	assert(received.count("attack_hit") == 1)

	bus.event_dispatched.connect(_on_chain_probe)
	assert(bus.publish("chain_probe"))
	await process_frame
	assert(chain_received == 9)
	print("CombatEvents smoke test passed: FIFO dispatch, duplicate suppression, chain depth limit.")
	quit(0)

func _on_event(event_name: String, _context: Dictionary) -> void:
	received.append(event_name)

func _on_chain_probe(event_name: String, _context: Dictionary) -> void:
	if event_name != "chain_probe":
		return
	chain_received += 1
	if chain_received < 20:
		bus.publish("chain_probe")
