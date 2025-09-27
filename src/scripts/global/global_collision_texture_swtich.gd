extends Node

func _ready():
	set_process(true)

func _process(_delta):
	# Глобальная обработка кнопки debug
	if Input.is_action_just_pressed("debug"):
		global_vars.debug_mode = !global_vars.debug_mode
		show_all_collision_textures()

func show_all_collision_textures():
	# Находим все узлы с "collision_texture" в имени
	var scene_root = get_tree().current_scene
	var collision_textures = find_nodes_by_pattern(scene_root, "collision_texture")
	
	# Показываем/скрываем в зависимости от debug_mode
	for node in collision_textures:
		node.visible = global_vars.debug_mode

func find_nodes_by_pattern(root_node: Node, pattern: String) -> Array:
	var found_nodes = []
	search_recursive(root_node, pattern, found_nodes)
	return found_nodes

func search_recursive(node: Node, pattern: String, found_nodes: Array):
	if pattern in node.name:
		found_nodes.append(node)
	
	for child in node.get_children():
		search_recursive(child, pattern, found_nodes)
