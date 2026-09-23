extends Node

@export var close_method := ""
@export var initial_repeat_delay := 0.65
@export var repeat_interval := 0.32
@export var stick_deadzone := 0.55

var _repeat_timer := 0.0
var _held_direction := Vector2.ZERO

func _process(delta: float) -> void:
	var close_target := _find_close_target()
	if close_target == null or not close_target.visible:
		_held_direction = Vector2.ZERO
		_repeat_timer = 0.0
		return

	var direction := _get_menu_direction()
	if direction == Vector2.ZERO:
		_held_direction = Vector2.ZERO
		_repeat_timer = 0.0
		return

	if direction != _held_direction:
		_held_direction = direction
		_repeat_timer = initial_repeat_delay
		_move_focus(direction)
		return

	_repeat_timer -= delta
	if _repeat_timer <= 0.0:
		_repeat_timer = repeat_interval
		_move_focus(direction)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B):
		return

	var owner_control := _find_close_target()
	if owner_control == null or not owner_control.visible:
		return

	var listening = owner_control.get("listening_for_action")
	if listening is String and listening != "":
		return

	if close_method != "" and owner_control.has_method(close_method):
		var viewport := get_viewport()
		owner_control.call(close_method)
		if is_instance_valid(viewport):
			viewport.set_input_as_handled()

func _find_close_target() -> Control:
	var node: Node = get_parent()
	while node != null:
		if node is Control and close_method != "" and node.has_method(close_method):
			return node
		node = node.get_parent()
	return null

func _get_menu_direction() -> Vector2:
	var horizontal := Input.get_axis("controller_move_left", "controller_move_right")
	var vertical := Input.get_axis("controller_move_up", "controller_move_down")
	var direction := Vector2(horizontal, vertical)

	if direction.length() < stick_deadzone:
		return Vector2.ZERO

	if abs(direction.x) >= abs(direction.y):
		return Vector2(sign(direction.x), 0.0)
	return Vector2(0.0, sign(direction.y))

func _move_focus(direction: Vector2) -> void:
	var current := get_viewport().gui_get_focus_owner() as Control
	if current == null:
		return

	var scope := _find_close_target()
	if scope == null or not scope.visible:
		return

	var candidates: Array[Control] = []
	_collect_focusable(scope, candidates)

	var current_center := current.global_position + current.size * 0.5
	var best: Control = null
	var best_score := INF

	for candidate in candidates:
		if candidate == current or not is_instance_valid(candidate) or not candidate.visible:
			continue
		if candidate.focus_mode == Control.FOCUS_NONE:
			continue

		var center := candidate.global_position + candidate.size * 0.5
		var offset := center - current_center
		var forward := offset.dot(direction)
		if forward <= 2.0:
			continue

		var perpendicular: float = abs(offset.x if direction.y != 0.0 else offset.y)
		var score: float = perpendicular * 3.0 + offset.length()
		if score < best_score:
			best_score = score
			best = candidate

	if best != null:
		best.grab_focus()

func _collect_focusable(node: Node, result: Array[Control]) -> void:
	if node is Control and node.focus_mode != Control.FOCUS_NONE:
		result.append(node)

	for child in node.get_children():
		if child is CanvasItem and not child.visible:
			continue
		_collect_focusable(child, result)
