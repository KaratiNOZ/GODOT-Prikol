extends CanvasLayer

var color_rect: ColorRect

func _ready():
	color_rect = ColorRect.new()
	color_rect.color = Color.BLACK
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.modulate.a = 0.0
	add_child(color_rect)

func fade_to_scene(target_scene: String):
	global_vars.can_move = false
	# 1. Затемнение
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, 0.2)
	await tween.finished
	
	# 2. Меняем сцену ТОЛЬКО после затемнения
	get_tree().change_scene_to_file(target_scene)
	
	# 3. Ждем загрузки сцены
	await get_tree().process_frame
	
	# 4. Осветление
	var tween2 = create_tween()
	tween2.tween_property(color_rect, "modulate:a", 0.0, 0.2)
	await tween2.finished
	
	# Включаем управление обратно
	global_vars.can_move = true
