extends CharacterBody2D

# --- ПЕРЕМЕННЫЕ ВРАГА --- #
var ENEMY = self                              # Ссылка на самого себя
var ENEMY_HP: int = 1500                      # Здоровье врага
var ENEMY_WALK_SPEED: int = 90                # Скорость передвижения врага

var IS_CHASING: bool = false                  # Преследует ли враг игрока
var ENEMY_SPRITE_GET_DAMAGE: bool = false     # Получает ли враг урон в данный момент
var ENEMY_TWEEN: Tween                        # Твин для анимации движения врага

# --- ПЕРЕМЕННЫЕ UI --- #
var fight_background: ColorRect = null        # Задний фон боя
var frame_parent: Node2D = null               # Родительский узел для рамки диалога
var frame: Panel = null                       # Рамка для текста диалога
var buttons: Array[Sprite2D] = []             # Массив кнопок интерфейса
var hp_sprite: Sprite2D = null                # Спрайт здоровья игрока
var _player_choice: int = 0                   # Выбор игрока в меню
var label: Label = null                       # Лейбл для отображения текста
var monologue_data = {}                       # Данные монологов из JSON файла
var monologue: int = 0                        # Текущий индекс монолога

# --- ПЕРЕМЕННЫЕ ИГРОКА --- #
var player = null                             # Ссылка на игрока
var in_fight: bool = false                    # Находится ли игрок в бою
var player_turn: bool = false                 # Ход игрока или врага
var player_choice: int = 0

func _ready() -> void:
	player = get_tree().current_scene.get_node("player") # Получаем ссылку на игрока
	$area_vision.body_entered.connect(_on_body_entered)  # Подключаем сигнал входа в зону видимости
	$area_vision.body_exited.connect(_on_body_exited)    # Подключаем сигнал выхода из зоны видимости

# --- ОБРАБОТЧИКИ СИГНАЛОВ AREA2D --- #
func _on_body_entered(body):
	IS_CHASING = true                         # Начинаем преследование игрока

func _on_body_exited(body):
	IS_CHASING = false                        # Прекращаем преследование игрока

func load_monologue():
	var file = FileAccess.open("res://src/dialoges/testEnemy.json", FileAccess.READ) # Открываем JSON файл с диалогами
	if file:
		var json_string = file.get_as_text()  # Читаем содержимое файла
		file.close()                          # Закрываем файл
		var json = JSON.new()                 # Создаём парсер JSON
		var parse_result = json.parse(json_string) # Парсим JSON строку
		if parse_result == OK:
			monologue_data = json.data        # Сохраняем данные диалогов
		else:
			print("Ошибка парсинга JSON: ", json.get_error_message())
			monologue_data = {}               # Устанавливаем пустые данные при ошибке
	else:
		print("Не удалось открыть файл res://src/dialoges/testEnemy.json")
		monologue_data = {}                   # Устанавливаем пустые данные при ошибке

func _physics_process(delta: float) -> void:
	if not IS_CHASING or in_fight:            # Если не преследуем или в бою
		return                                # Прекращаем обработку движения
	
	var dir = (player.position - position).normalized() # Вычисляем направление к игроку
	var collision = move_and_collide(dir * ENEMY_WALK_SPEED * delta) # Двигаемся в сторону игрока
	
	if collision and collision.get_collider() == player: # Если столкнулись с игроком
		in_fight = true                       # Начинаем бой
		IS_CHASING = false                    # Прекращаем преследование
		global_vars.can_move = false          # Блокируем движение игрока
		await get_tree().create_timer(0.2).timeout # Небольшая задержка
		setup_fight()                         # Запускаем настройку боевого экрана
	
func _process(delta: float) -> void:
	if not in_fight:                          # Если не в бою
		if global_vars.player_y > position.y + 5: # Если игрок ниже врага
			self.z_index = 0                  # Враг позади игрока
		else:
			self.z_index = 1                  # Враг перед игроком
	
	# --- ВО ВРЕМЯ БОЯ И НЕ ТОЛЬКО --- #
	if in_fight:
		match global_vars.player_hp:
			2:
				hp_sprite.texture = load("res://assets/sprites/hp_2_3.png")   # Изменяем спрайт на хп  2 / 3
			1:
				hp_sprite.texture = load("res://assets/sprites/hp_1_3.png")   # Изменяем спрайт на хп  1 / 3
			_:
				print("Здоровье игрока не является числом")    # Принт на случай ошибок
	
	# --- ПЕРЕКЛЮЧЕНИЕ КНОПОК --- #
	if in_fight and player_turn:
		if Input.is_action_just_pressed("arrow_right"):
			player_choice = 1
			buttons[1].texture = load("res://assets/sprites/run_active.png")
			buttons[0].texture = load("res://assets/sprites/attack_non_active.png")
		elif Input.is_action_just_pressed("arrow_left"):
			player_choice = 0
			buttons[0].texture = load("res://assets/sprites/attack_active.png")
			buttons[1].texture = load("res://assets/sprites/run_non_active.png")
		if player_choice == 1 and Input.is_action_just_pressed("Z"):
			get_tree().quit()
		

func animate_sprite(sprite: AnimatedSprite2D) -> void:
	if not ENEMY_SPRITE_GET_DAMAGE:           # Если враг не получает урон
		var sprite_center = sprite.position   # Центральная позиция спрайта
		var A = 10                            # Амплитуда по X (ширина восьмерки)
		var B = 5                             # Амплитуда по Y (высота восьмерки)
		
		ENEMY_TWEEN = create_tween()          # Создаём твин для анимации
		ENEMY_TWEEN.set_loops()               # Зацикливаем анимацию
		
		# Анимируем параметр времени от 0 до 1 за 3 секунды
		ENEMY_TWEEN.tween_method(
			func(progress): 
				# Преобразуем прогресс (0-1) в параметр t
				var t = progress * 2 * PI
				
				# Вычисляем смещение по формуле восьмерки
				var offset_x = A * sin(t)
				var offset_y = B * sin(2 * t)
				
				sprite.position = sprite_center + Vector2(offset_x, offset_y), # Применяем смещение
			0.0,                              # Начальное значение прогресса
			1.0,                              # Конечное значение прогресса
			3.0                               # Время анимации в секундах
		).set_trans(Tween.TRANS_LINEAR)       # Линейная интерполяция
		
		random_sprite(sprite)                 # Запускаем случайную смену анимаций спрайта

func random_sprite(sprite: AnimatedSprite2D):
	var delay = randi_range(3, 6)             # Случайная задержка от 3 до 6 секунд
	var next_sprite = randi_range(1, 3)       # Случайный номер анимации от 1 до 3
	
	var timer = get_tree().create_timer(delay) # Создаём таймер с задержкой
	timer.timeout.connect(func():
		match next_sprite:                    # Выбираем анимацию по номеру
			1: sprite.play("1")               # Воспроизводим анимацию "1"
			2: sprite.play("2")               # Воспроизводим анимацию "2"
			3: sprite.play("3")               # Воспроизводим анимацию "3"
		random_sprite(sprite)                 # Рекурсивно запускаем следующую смену
		)

func setup_fight() -> void:
	# --- ЗАДНИК --- #
	
	fight_background = ColorRect.new()                    # Создание задника
	get_tree().current_scene.add_child(fight_background)  # Сразу добавление его в сцену
	ENEMY.z_index = 2                                     # Заранее делаем его выше заднего фона
	
	# Настройка задника
	fight_background.color = Color.BLACK       # Цвет заливки
	fight_background.z_index = 1               # его z индекс
	fight_background.modulate.a = 0.0          # начальная прозрачность
	fight_background.size = Vector2(640, 480)  # задаём размер
	fight_background.position = Vector2(0, 0)  # задаём позицию
	
	# Целевые координаты позиции и размера для спрайта врага во время боя
	var target_enemy_pos = Vector2(320, 100)
	var target_enemy_scale = Vector2(1.5, 1.5)
	
	# Создаем твин для управлением анимации
	var tween = create_tween()
	tween.tween_property(fight_background, "modulate:a",   1.0,       0.2) # Изменяем прозрачность за 0.2 секунды
						# Цель               свойство    значение    время   
	tween.parallel().tween_property(ENEMY, "position", target_enemy_pos, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)  # Изменяем позицию врага, чтобы он был сверху и был виден во время боя
	tween.parallel().tween_property(ENEMY, "scale", target_enemy_scale, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)   # Изменяем размер врага, чтобы его было видно
	
	
	# --- UI ИГРОКА --- #
	
	
	# Инициализация кнопок
	buttons.resize(4)
	
	# Кнопки атаки не активная
	buttons[0] = Sprite2D.new()                                             # Тип объекта
	buttons[0].texture = load("res://assets/sprites/attack_non_active.png") # Путь до текстуры
	buttons[0].position = Vector2(-100, 410)                                # Изначальные координаты кнопки
	buttons[0].scale = Vector2(2.5, 2.5)                                    # Размер кнопки
	fight_background.add_child(buttons[0])                                  # Добавляем его как дочерний элемент задника
	
	# Кнопки побега не активная
	buttons[1] = Sprite2D.new()                                             # Тип объекта
	buttons[1].texture = load("res://assets/sprites/run_non_active.png")    # Путь до текстуры
	buttons[1].position = Vector2(700, 410)                                 # Изначальные координаты кнопки
	buttons[1].scale = Vector2(2.5, 2.5)                                    # Размер кнопки
	fight_background.add_child(buttons[1])                                  # Добавляем его как дочерний элемент задника
	
	# Здоровье игрока
	hp_sprite = Sprite2D.new()                                              # Тип объекта
	hp_sprite.texture = load("res://assets/sprites/hp_3_3.png")             # Путь до текстуры
	hp_sprite.position = Vector2(320, 500)                                  # Изначальные координаты элемента
	hp_sprite.scale = Vector2(1, 1)                                         # Размер элемента
	fight_background.add_child(hp_sprite)                                   # Добавляем его как дочерний элемент задника
	
	
	# Рамка для боя и монологов (я хз как её ещё назвать)
	frame_parent = Node2D.new()                                             # Создаём родитель для рамки, чтобы было проще управлять
	frame_parent.position = Vector2(320, 270)                               # Устанавлием позицию для родителя
	fight_background.add_child(frame_parent)                                # Добавляем его как дочерний элемент задника
	
	frame = Panel.new()                                                     # Тип объекта
	frame.z_index = 3                                                       # Делаем z индекс выше чем индекс врага, чтобы враг не перекрывал рамку
	frame.modulate.a = 0.0                                                  # Начальная прозрачность
	frame.size = Vector2(435, 180)                                          # Размер рамки
	
	var frame_style = StyleBoxFlat.new()                                    # Создаем стиль для рамки, чтобы залить и настроить края рамки
	frame_style.bg_color = Color.BLACK                                      # Цвет заливки рамки
	frame_style.border_color = Color.WHITE                                  # Цвет граней рамки
	frame_style.border_width_left =   5                                     # Размер каждой грани рамки
	frame_style.border_width_right =  5
	frame_style.border_width_top =    5
	frame_style.border_width_bottom = 5
	frame.add_theme_stylebox_override("panel", frame_style)                 # Присвоение стиля для рамки

	frame_parent.add_child(frame)                                           # Добавляем рамку в родителя-рамку
	frame.position = -frame.size / 2                                        # Центрируем относительно родителя   
	
	# Анимция для появления элементов
	tween.tween_property(buttons[0], "position", Vector2(160, 410), 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(buttons[1], "position", Vector2(480, 410), 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(hp_sprite, "position", Vector2(320, 410), 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(frame, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_LINEAR)
	
	tween.tween_callback(func() -> void:                 # Ждём окончание всех твинов и только тогда запускаем
		animate_sprite(ENEMY.get_node("enemy_texture"))  # Передаём текстуру врага
		setup_text()                                     # Настраиваем текст диалога
		player_turn = true                               # Игра начинается
	)

func setup_text() -> void:
	label = Label.new()                         # Создание лейбла для текста
	frame_parent.add_child(label)               # Добавляем в родительскую рамку
	
	# Отступы для текста
	var left_margin   = 20                      # Отступ слева
	var right_margin  = 20                      # Отступ справа
	var top_margin    = 10                      # Отступ сверху
	var bottom_margin = 20                      # Отступ снизу
	
	# Позиционируем и изменяем размер с учетом отступов
	label.position = -Vector2(frame.size.x / 2 - left_margin, frame.size.y / 2 - top_margin) # Позиция с учетом отступов
	label.size = Vector2(frame.size.x - left_margin - right_margin, frame.size.y - top_margin - bottom_margin) # Размер с учетом отступов
	label.z_index = 4                           # Делаем поверх рамки, чтоб видно было
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Перенос слов
	
	# Настраиваем внешний вид текста
	label.add_theme_font_size_override("font_size", 20)           # Размер шрифта
	label.add_theme_color_override("font_color", Color.WHITE)     # Цвет текста
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT        # Выравнивание по левому краю
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP             # Выравнивание по верхнему краю
	label.visible_ratio = 0.0                   # Изначально текст скрыт
	
	# Загружаем и показываем первый монолог
	load_monologue()                            # Загружаем данные диалогов
	show_next_monologue()                       # Показываем первый монолог

func show_next_monologue():
	# Загружаем данные, если еще не загружены
	if monologue_data.is_empty():               # Если данные не загружены
		load_monologue()                        # Загружаем их
	
	var text_to_show = ""                       # Текст для отображения
	
	# Если monologue <= 10, показываем последовательно
	if monologue <= 10:                         # Если индекс меньше или равен 10
		# Ищем текст с нужным id
		for dialogue in monologue_data["test_enemy"]: # Перебираем все диалоги
			if dialogue["id"] == monologue:     # Если нашли нужный id
				text_to_show = dialogue["text"] # Сохраняем текст
				break                           # Прерываем поиск
		
		# Увеличиваем счетчик для следующего раза
		monologue += 1                          # Переходим к следующему монологу
		print("Showing monologue id: ", monologue - 1, " Next will be: ", monologue)
	else:
		# После id 10 выбираем случайный текст
		var random_index = randi_range(0, monologue_data["test_enemy"].size() - 1) # Случайный индекс
		text_to_show = monologue_data["test_enemy"][random_index]["text"] # Случайный текст
		print("Showing random monologue: ", monologue_data["test_enemy"][random_index]["id"])
	
	# Если текст найден, запускаем анимацию печатания
	if text_to_show != "":                      # Если текст не пустой
		start_typing_animation(text_to_show)    # Запускаем анимацию печатания
	else:
		print("Текст с id ", monologue - 1, " не найден!")
		
func start_typing_animation(text: String):
	label.text = text                           # Устанавливаем текст в лейбл
	label.visible_ratio = 0.0                   # Скрываем весь текст
	
	# Останавливаем предыдущую анимацию, если она есть
	if has_method("get_typing_tween") and get("typing_tween") != null: # Если есть активная анимация
		var old_tween = get("typing_tween")     # Получаем старый твин
		if is_instance_valid(old_tween):        # Если он валидный
			old_tween.kill()                    # Останавливаем его
	
	# Создаем новый tween для анимации
	var typing_tween = create_tween()           # Создаём новый твин
	set("typing_tween", typing_tween)           # Сохраняем ссылку на него
	
	# Вычисляем общее время анимации
	var total_time = text.length() * 0.03       # Время = количество символов * 0.03 секунды
	
	# Анимируем visible_ratio от 0 до 1
	typing_tween.tween_property(label, "visible_ratio", 1.0, total_time).set_trans(Tween.TRANS_LINEAR) # Плавно показываем текст
	
	# Callback для завершения анимации
	typing_tween.tween_callback(func():
		print("Typing animation finished")      # Выводим сообщение о завершении
		set("typing_tween", null)               # Очищаем ссылку на твин
	)
	
