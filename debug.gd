extends Label


func _process(delta: float) -> void:
	text = str("fps: ", Engine.get_frames_per_second(), " delta: ", delta)
