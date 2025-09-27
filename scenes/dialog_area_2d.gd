extends Area2D
var player_in_area = false
var player = null
var dialog_box = null
var style = null
var label_text = null
var text_settings = null
var margin = null
var is_done = false
var dialogue_data = {}
var current_dialogue_id = 1
var choice_labels = []
var current_choices = []
var selected_choice = 0
var is_typing = false
var choices_visible = false
var waiting_for_choices = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	load_dialogue()

func load_dialogue():
	var file = FileAccess.open("res://src/dialoges/Testnpc.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			dialogue_data = json.data
		else:
			print("Ошибка парсинга JSON: ", json.get_error_message())
			dialogue_data = {}
	else:
		print("Не удалось открыть файл res://src/dialoges/Testnpc.json")
		dialogue_data = {}

func _on_body_entered(body):
	if body.name == "player":
		player_in_area = true
		player = body
		print("Игрок вошел в зону диалога")

func _on_body_exited(body):
	if body.name == "player":
		player_in_area = false
		player = null
		print("Игрок вышел из зоны диалога")

func _input(event):
	if not player_in_area:
		return
	
	if event.is_action_pressed("Z"):
		if dialog_box == null and global_vars.last_dir == "back":
			start_dialog()
		elif is_typing:
			skip_typing()
		elif waiting_for_choices:
			clear_text_and_show_choices()
		elif choices_visible:
			select_current_choice()
		elif is_done and not choices_visible:
			close_dialog()
	
	if choices_visible:
		if event.is_action_pressed("ui_up") and selected_choice > 0:
			selected_choice -= 1
			update_choice_selection()
		elif event.is_action_pressed("ui_down") and selected_choice < current_choices.size() - 1:
			selected_choice += 1
			update_choice_selection()

func start_dialog():
	is_done = false
	global_vars.can_move = false
	show_dialogue(current_dialogue_id)

func show_dialogue(id):
	if not dialogue_data.has("npc_dialogue"):
		print("Ошибка: npc_dialogue не найден в данных")
		close_dialog()
		return
	
	var dialogue = null
	for d in dialogue_data["npc_dialogue"]:
		if d["id"] == id:
			dialogue = d
			break
	
	if dialogue == null:
		close_dialog()
		return

	# Проверяем на специальные действия
	if id == 43:
		execute_action(id)
		return

	create_dialog_box()
	label_text.text = dialogue["text"]
	
	if dialogue.has("choices"):
		current_choices = dialogue["choices"]
	else:
		current_choices = []
	
	start_typig_animation(label_text)

func execute_action(action_id):
	match action_id:
		43, 43.0:
			global_vars.npc_fade = true
			# Удаляем весь родительский узел NPC из сцены
			get_parent().queue_free()
			close_dialog()
		_:
			print("Неизвестное действие: ", action_id)

func create_dialog_box():
	if dialog_box:
		dialog_box.queue_free()
		clear_choices()
	
	dialog_box = Panel.new()
	
	style = StyleBoxFlat.new()
	style.bg_color = Color.BLACK
	style.border_color = Color.WHITE
	style.border_width_left = 5
	style.border_width_right = 5
	style.border_width_top = 5
	style.border_width_bottom = 5
	
	dialog_box.z_index = 2
	dialog_box.add_theme_stylebox_override("panel", style)
	dialog_box.size = Vector2(600, 150)
	dialog_box.position = Vector2((640/2) - (dialog_box.size.x / 2), 480/2 + 75)
	
	label_text = Label.new()
	text_settings = LabelSettings.new()
	margin = dialog_box.size * 0.03
	
	dialog_box.add_child(label_text)
	
	text_settings.font_size = 26
	
	label_text.visible_ratio = 0
	label_text.label_settings = text_settings
	label_text.z_index = 2
	label_text.position = Vector2(margin.x, margin.y)
	label_text.size = Vector2(dialog_box.size.x - margin.x * 2, dialog_box.size.y - margin.y * 2)
	label_text.clip_text = true
	
	get_tree().current_scene.add_child(dialog_box)

func clear_text_and_show_choices():
	label_text.text = ""
	waiting_for_choices = false
	show_choices()

func show_choices():
	if current_choices.size() == 0:
		return
	
	clear_choices()
	choices_visible = true
	selected_choice = 0
	
	for i in range(current_choices.size()):
		var choice = current_choices[i]
		var choice_label = Label.new()
		var choice_settings = LabelSettings.new()
		choice_settings.font_size = 26
		
		choice_label.label_settings = choice_settings
		choice_label.text = "* " + choice["player"]
		choice_label.position = Vector2(margin.x, 10 + i * 25)
		choice_label.z_index = 3
		
		dialog_box.add_child(choice_label)
		choice_labels.append(choice_label)
	
	update_choice_selection()

func update_choice_selection():
	for i in range(choice_labels.size()):
		if i == selected_choice:
			choice_labels[i].modulate = Color.YELLOW
		else:
			choice_labels[i].modulate = Color.WHITE

func select_current_choice():
	var next_id = current_choices[selected_choice]["next"]
	clear_choices()
	choices_visible = false
	
	if next_id != null:
		show_dialogue(next_id)
	else:
		close_dialog()

func clear_choices():
	for label in choice_labels:
		label.queue_free()
	choice_labels.clear()

func close_dialog():
	if dialog_box:
		dialog_box.queue_free()
		dialog_box = null
		clear_choices()
		is_done = false
		choices_visible = false
		waiting_for_choices = false
		global_vars.can_move = true
		current_dialogue_id = 1

func start_typig_animation(label: Label):
	is_typing = true
	var symbol_cd = 0.03
	var text_length = label.text.length()
	
	if text_length == 0:
		is_typing = false
		is_done = true
		if current_choices.size() > 0:
			waiting_for_choices = true
		return
	
	for i in range(text_length + 1):
		if not is_typing:
			break
		label.visible_ratio = float(i) / float(text_length)
		await get_tree().create_timer(symbol_cd).timeout
	
	label.visible_ratio = 1.0
	is_typing = false
	is_done = true
	
	if current_choices.size() > 0:
		waiting_for_choices = true

func skip_typing():
	is_typing = false
	label_text.visible_ratio = 1.0
	is_done = true
	if current_choices.size() > 0:
		waiting_for_choices = true
