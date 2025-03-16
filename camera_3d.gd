extends Node3D

var relative : Vector2 = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		relative = event.relative

func _process(delta: float) -> void:
	if abs(relative.x) > 0:
		rotate_y(-relative.x * delta * 0.4)
	
	if abs(relative.y) > 0:
		$Camera3D.rotate_x(-relative.y * delta * 0.4)
	
	relative = Vector2.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
