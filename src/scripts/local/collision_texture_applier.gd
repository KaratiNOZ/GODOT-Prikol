extends Sprite2D
func _process(delta: float) -> void:
	if global_vars.debug_mode == true:
		var main_collision = get_parent()
		if main_collision is CollisionShape2D and main_collision.shape:
			var shape_size = main_collision.shape.get_rect().size
			var texture_size = self.texture.get_size()
			self.scale = shape_size / texture_size
			self.position = Vector2.ZERO  # Центрируем относительно родителя
	else:
		pass
