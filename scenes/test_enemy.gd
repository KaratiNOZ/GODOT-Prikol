extends CharacterBody2D

# --- ПЕРЕМЕННЫЕ ВРАГА --- #
var ENEMY = self                              # Ссылка на самого себя
var ENEMY_HP: int = 1200                      # Здоровье врага
var ENEMY_WALK_SPEED: int = 90                # Скорость передвижения врага

var IS_CHASING: bool = false                  # Преследует ли враг игрока
var ENEMY_SPRITE_GET_DAMAGE: bool = false     # Получает ли враг урон в данный момент
var ENEMY_TWEEN: Tween                        # Твин для анимации движения врага

var ENEMY_TURN: bool = false

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
var player_choice: int = -1                   # Выбор игрока (по умолчанию -1 т.к. кнопки будут не активны)
var player_mini = null
var player_mini_coll = null
var player_mini_texture = null
var player_mini_speed: float = 150
var player_last_move_dir: Vector2 = Vector2.ZERO

# --- ДЛЯ БОЯ --- #
var _bars_array: Array[Panel] = []             # Создаем массив для палок
var _current_index: int = 0                    # Текущей индекс палки
var _total_bars: int = 0                       # Общее количество палок
var _current_bar: Panel = null                 # Ссылка на текущую палку
var _bar_tween: Tween = null                   # Твин для анимации палки
var _middle_turn: bool = false

var tween_process: bool = false
var ready_to_tween: bool = false

func _ready() -> void:
	player = get_tree().current_scene.get_node("player") # Получаем ссылку на игрока
	player_mini = player.get_node("mind")
	player_mini_coll = player_mini.get_node("mind_collision")
	player_mini_texture = player_mini_coll.get_node("main_character")
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
		player.get_node("plr_main_collision").disabled = true
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
			0:
				get_tree().quit()
		
		# Передвижение на арене
		if not player_turn and ENEMY_TURN:
			var player_mini_dir = Vector2.ZERO
			
			if Input.is_action_pressed("ui_left"):
				player_mini_dir.x -= 1
			if Input.is_action_pressed("ui_right"):
				player_mini_dir.x += 1
			if Input.is_action_pressed("ui_up"):
				player_mini_dir.y -= 1
			if Input.is_action_pressed("ui_down"):
				player_mini_dir.y += 1
			
			if player_mini_dir != Vector2.ZERO:
				player_mini_dir = player_mini_dir.normalized()
				
				if player_mini_dir != player_last_move_dir:
					player_mini_texture.play("me")
					player_last_move_dir = player_mini_dir
				
				# Двигаем игрока
				player_mini.position += player_mini_dir * player_mini_speed * delta
				
				# Глобальные координаты левого верхнего угла рамки
				var frame_global_top_left = frame.get_global_position()

				# Половина размера рамки
				var half_size = frame.size / 2

				# Центр рамки
				var frame_center = frame_global_top_left + half_size

				# Ограничения движения
				var min_x = frame_center.x - half_size.x + 14
				var max_x = frame_center.x + half_size.x - 13
				var min_y = frame_center.y - half_size.y + 14
				var max_y = frame_center.y + half_size.y - 13

				# Ограничиваем глобальную позицию игрока
				player_mini.global_position.x = clamp(player_mini.global_position.x, min_x, max_x)
				player_mini.global_position.y = clamp(player_mini.global_position.y, min_y, max_y)
			else:
				player_last_move_dir = Vector2.ZERO

	
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
		if player_choice == 0 and Input.is_action_just_pressed("Z"):
			buttons[0].texture = load("res://assets/sprites/attack_non_active.png")
			player_turn = false
			player_choice = -1
			dmg_zone()
		if player_choice == 1 and Input.is_action_just_pressed("Z"):
			get_tree().quit()


func dmg_zone() -> void:
	if _middle_turn != false:
		delete_dmg_zone()
		return
		
	_bars_array.clear()  # Очищаем старый массив
	_current_index = 0   # Сбрасываем индекс
	_current_bar = null  # Сбрасываем текущую палку
	
	var damage_zone = Sprite2D.new()    # Создаём зону урона по врагу
	damage_zone.name = "Damage_Zone"    # Устанавливаем имя, чтобы можно было найти
	frame_parent.add_child(damage_zone) # Сразу его добавляем его в родительскую рамку
	
	var margin = 5  # Отступ со всех сторон
	
	damage_zone.texture = load("res://assets/sprites/damage_zone.png")    # Загружаем его текстуру
	
	# Начальный размер (невидимый по высоте)
	damage_zone.scale = Vector2((frame.size.x - margin * 2) / damage_zone.texture.get_width(), 0)
	damage_zone.z_index = 3 # Просто делаем чтобы был выше слоем
	damage_zone.position = Vector2(0, 0) # Позиционируем в центре frame
	
	# Целевой размер
	var target_dz_scale = Vector2((frame.size.x - margin * 2) / damage_zone.texture.get_width(), 3)
	
	# Вычисляем целевую высоту damage_zone после масштабирования
	var target_damage_zone_height = damage_zone.texture.get_height() * target_dz_scale.y
	
	# Целевой размер frame с учётом отступов
	var target_frame_size_y = target_damage_zone_height + margin * 2 - 1
	
	# Удаляем текст чтобы не мешал
	frame_parent.remove_child(label)
	
	# Вычисляем целевую позицию frame
	var target_frame_position = Vector2(-frame.size.x / 2, -target_frame_size_y / 2)
	
	# Создаём анимацию
	var tween = create_tween()
	tween.tween_property(damage_zone, "scale", target_dz_scale, 0.5)
	tween.parallel().tween_property(frame, "size:y", target_frame_size_y, 0.5)
	tween.parallel().tween_property(frame, "position:y", target_frame_position.y, 0.5)
	
	# После завершения анимации создаём палки
	tween.tween_callback(func() -> void:
		
		# Теперь создаём палки с правильной высотой
		for i in range(randi_range(4, 6)):
			var bar = Panel.new()  # Сам тип объекта
			var bar_style = StyleBoxFlat.new() # Для его стиля
			frame_parent.add_child(bar) # Сразу добавляем его в родительскую рамку чтобы небыло траблов
			
			bar.z_index = 4  # Делаем выше слоем
			bar.size.x = 10  # Его размер по X
			bar.size.y = target_damage_zone_height # Его высота по Y
			
			bar.position.x = -5 # Центрируем его по центру сначала 
			bar.position.y = frame.position.y + margin - 1 # Центрируем по Y с учётом отступа
			
			bar_style.bg_color = Color.BLACK     # Цвет заливки задника
			bar_style.border_color = Color.WHITE # Цвет краёв
			
			# Размер краёв
			bar_style.border_width_bottom = 2
			bar_style.border_width_top = 2
			bar_style.border_width_left = 2
			bar_style.border_width_right = 2
			
			bar.visible = false  # По умолчанию делаем невидимым 
			bar.add_theme_stylebox_override("panel", bar_style)  # Присваеваем стиль
			
			_bars_array.append(bar) # Добавляем в массив
		
		# Запускаем палки последовательно
		spawn_bars_sequentially(_bars_array, 0, _bars_array.size())
		print("Размер массива: ", _bars_array.size())
	)


func spawn_bars_sequentially(bars_array: Array[Panel], index: int, total_bars: int) -> void:
	if index >= bars_array.size() or _middle_turn != false:
		for bar in bars_array:
			if is_instance_valid(bar):
				# Убиваем возможный tween, привязанный к палке
				if bar.has_meta("tween"):
					var t = bar.get_meta("tween")
					if t and is_instance_valid(t):
						t.kill()
					bar.remove_meta("tween")
				bar.queue_free()
		_bars_array.clear()
		_current_bar = null
		_current_index = 0
		delete_dmg_zone()
		return
	
	var current_spawned_bar = bars_array[index]
	
	# Проверяем что палка всё ещё существует перед использованием
	if not is_instance_valid(current_spawned_bar):
		#print("Палка ", index + 1, " уже была удалена, пропускаем")
		spawn_bars_sequentially(bars_array, index + 1, total_bars)
		return
	
	# Устанавливаем первую палку как активную
	if index == 0:
		_current_bar = current_spawned_bar
		_current_index = 0
	
	var start_position = randi_range(0, 1)
	var start_x: float
	var target_x: float
	
	match start_position:
		0:
			start_x = -214
			target_x = 204
		1:
			start_x = 204
			target_x = -214

	current_spawned_bar.position.x = start_x
	current_spawned_bar.visible = true
	
	var bar_tween = create_tween()
	bar_tween.parallel().tween_property(current_spawned_bar, "position:x", target_x, 1.0)
	current_spawned_bar.set_meta("tween", bar_tween)
	bar_tween.finished.connect(func() -> void:
		if is_instance_valid(current_spawned_bar):
			current_spawned_bar.queue_free()
			#print("Палка ", index + 1, " дошла до конца и удалена")
			
			# Если это была активная палка, переключаемся на следующую
			if _current_bar == current_spawned_bar:
				_current_index = index + 1
				if _current_index < _bars_array.size():
					_current_bar = _bars_array[_current_index]
					#print("Активная палка теперь: ", _current_index + 1)
				else:
					_current_bar = null
					#print("Все палки завершены")
			
			if index + 1 == total_bars:
				delete_dmg_zone()
	)
	
	var delay = randf_range(0.3, 0.6)
	await get_tree().create_timer(delay).timeout
	
	spawn_bars_sequentially(bars_array, index + 1, total_bars)

func victory() -> void:
	_middle_turn = true
	frame_to_start()
	ENEMY_TURN = false
	ENEMY_SPRITE_GET_DAMAGE = true
	player_turn = false
	player_choice = -1

	# Останавливаем ENEMY_TWEEN, если он активен
	if ENEMY_TWEEN != null and is_instance_valid(ENEMY_TWEEN):
		ENEMY_TWEEN.kill()
		ENEMY_TWEEN = null

	var sprite = ENEMY.get_node("enemy_texture")
	if sprite:
		sprite.stop()

	# 1. Исчезновение врага (короткая анимация)
	var enemy_fade_tween = create_tween()
	enemy_fade_tween.tween_property(ENEMY, "modulate:a", 0.0, 0.4)
	# не ждём тут окончания — продолжение по нажатию Z

	# 2. Создаем черный экран перехода и делаем видимым
	var trans_back = ColorRect.new()
	trans_back.name = "VictoryTransBack"
	trans_back.color = Color.BLACK
	trans_back.modulate.a = 0.0
	trans_back.z_index = 999
	trans_back.size = Vector2(640, 480)
	trans_back.position = Vector2(0, 0)
	get_tree().current_scene.add_child(trans_back)

	# 3. Готовы к ожиданию нажатия Z — дальше продолжит _input
	ready_to_tween = true

func continue_victory() -> void:
	# Немедленно предотвращаем повторный вход
	if not ready_to_tween:
		return

	# Найдём наш trans_back (если он есть)
	var trans_back = get_tree().current_scene.get_node_or_null("VictoryTransBack")
	if trans_back == null:
		# Если по какой-то причине экран не найден — создадим локально, чтобы не упасть
		trans_back = ColorRect.new()
		trans_back.color = Color.BLACK
		trans_back.modulate.a = 0.0
		trans_back.z_index = 999
		trans_back.size = Vector2(640, 480)
		trans_back.position = Vector2(0, 0)
		get_tree().current_scene.add_child(trans_back)

	# 4. Затемнение экрана
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(trans_back, "modulate:a", 1.0, 0.5)
	await fade_in_tween.finished

	# 5. Удаляем все элементы боя — более надёжно: удаляем контейнер fight_background и ENEMY
	if is_instance_valid(fight_background):
		# Если хотим гарантированно удалить все дочерние узлы — скопируем массив и удалим
		for child in fight_background.get_children():
			if is_instance_valid(child):
				child.queue_free()
		fight_background.queue_free()
		fight_background = null



	# 6. Осветление экрана
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(trans_back, "modulate:a", 0.0, 0.5)
	await fade_out_tween.finished
	
	global_vars.can_move = true

	# 7. Удаляем trans_back
	if is_instance_valid(trans_back):
		trans_back.queue_free()

	# Сбрасываем флаги и возвращаем управление игроку
	_middle_turn = false
	tween_process = false
	ready_to_tween = false
	in_fight = false
	fight_background = null
	frame_parent = null
	frame = null
	label = null
	buttons.clear()
	hp_sprite = null
	
	player.get_node("plr_main_collision").disabled = false
	
	# Удаляем все временные боевые объекты, которые могли быть добавлены в ENEMY
	if is_instance_valid(ENEMY):
		# Лучше удалить все дочерние элементы, чтобы очистить всё, а затем удалить ENEMY
		for c in ENEMY.get_children():
			if is_instance_valid(c):
				c.queue_free()
		ENEMY.queue_free()
		ENEMY = null

func _input(event: InputEvent) -> void:
	if ready_to_tween and event.is_action_pressed("Z"):
		print("Продолжаем")
		continue_victory()
		return
	
	if not in_fight:
		return
	
	if ENEMY_HP <= 0 and ready_to_tween != true:
		victory()
		return
	
	if event.is_action_pressed("Z"):
		# Проверяем, есть ли активная палка
		if _current_bar != null and is_instance_valid(_current_bar):
			if _current_index >= _bars_array.size():
				print("Индекс вне границ массива!")
				return
			# Получаем позицию палки по X
			var bar_x = _current_bar.position.x
			# Список диапазонов и урона
			var damage_zones = [
				{ "min": -214.0, "max": -96.0,  "dmg": 10 },
				{ "min": -96.0,  "max": -31.0,  "dmg": 50 },
				{ "min": -22.0,  "max": 12.0,   "dmg": 90 },
				{ "min": -5.0,   "max": -5.0,   "dmg": 160 }, # точечное попадание
				{ "min": 20.0,   "max": 95.0,   "dmg": 50 },
				{ "min": 103.0,  "max": 204.0,  "dmg": 10 },
			]
			
			for zone in damage_zones:
				if bar_x >= zone.min and bar_x <= zone.max:
					ENEMY_HP -= zone.dmg
					break  # чтобы не применилось несколько раз
			
			# Останавливаем все твины связанные с этой палкой
			if _current_bar.has_meta("tween"):
				var tween = _current_bar.get_meta("tween")
				if tween and is_instance_valid(tween):
					tween.kill()
				_current_bar.remove_meta("tween")
			
			# Удаляем активную палку
			_current_bar.queue_free()
			#print("Палка удалена игроком")
			
			# Переключаемся на следующую активную палку
			_current_index += 1
			if _current_index < _bars_array.size():
				_current_bar = _bars_array[_current_index]
				# Проверяем что новая активная палка всё ещё валидна
				if not is_instance_valid(_current_bar):
					_current_bar = null
					delete_dmg_zone()
				else:
					pass
					#print("Следующая активная палка: ", _current_index + 1)
			else:
				_current_bar = null
				#print("Все палки завершены")
				print("Здоровья врага: ", ENEMY_HP)
				ENEMY_SPRITE_GET_DAMAGE = true
				animate_sprite(ENEMY.get_node("enemy_texture"))
				delete_dmg_zone()



func animate_sprite(sprite: AnimatedSprite2D) -> void:
	var sprite_center = sprite.position   # Центральная позиция спрайта
	
	if not ENEMY_SPRITE_GET_DAMAGE:
		var A = 10  # Амплитуда по X (ширина восьмерки)
		var B = 5   # Амплитуда по Y (высота восьмерки)
		
		# Основная "восьмёрка" анимация
		ENEMY_TWEEN = create_tween()
		ENEMY_TWEEN.set_loops()
		
		ENEMY_TWEEN.tween_method(
			func(progress): 
				var t = progress * 2 * PI
				var offset_x = A * sin(t)
				var offset_y = B * sin(2 * t)
				sprite.position = sprite_center + Vector2(offset_x, offset_y),
			0.0,
			1.0,
			3.0
		).set_trans(Tween.TRANS_LINEAR)
		
		random_sprite(sprite) # Смена анимаций спрайта
	
	else:
		# Если враг получает урон
		sprite.play("get_damage")
		
		# Возможные направления отскока (включая диагонали)
		var directions = [
			Vector2(-20, 0), Vector2(20, 0),   # Влево / вправо
			Vector2(0, -20), Vector2(0, 20),   # Вверх / вниз
			Vector2(-20, -20), Vector2(20, -20), # Диагонали вверх
			Vector2(-20, 20), Vector2(20, 20)    # Диагонали вниз
		]
		var knockback = directions[randi() % directions.size()]
		
		# Твин для отскока
		var knockback_tween = create_tween()
		knockback_tween.tween_property(sprite, "position", sprite_center + knockback, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
		knockback_tween.tween_property(sprite, "position", sprite_center, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT_IN)
	
		knockback_tween.finished.connect(func():
			ENEMY_SPRITE_GET_DAMAGE = false
			animate_sprite(sprite)
			)


func random_sprite(sprite: AnimatedSprite2D):
	if not ENEMY_SPRITE_GET_DAMAGE:
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


func delete_dmg_zone() -> void:
	_bars_array.clear()  # Очищаем старый массив
	_current_index = 0   # Сбрасываем индекс
	_current_bar = null  # Сбрасываем текущую палк
	
	print("Удаления зоны урона")
	
	var damage_zone: Sprite2D = null
	for child in frame_parent.get_children():
		if child is Sprite2D:
			damage_zone = child
			break
	
	if damage_zone:
		damage_zone.queue_free()
		print("Зона удалилась")
	
	if _middle_turn == true:
		return
		
	var tween = create_tween()
	print("Враг атакует!")
	
	# Анимируем размер
	tween.parallel().tween_property(frame, "size", Vector2(185, 185), 0.5)
	
	# Анимируем позицию (она должна сместиться в центр по новому размеру)
	tween.parallel().tween_property(frame, "position", -Vector2(185, 185) / 2, 0.5)
	
	tween.tween_callback(func() -> void:
		enemy_turn_attack()
	)


func enemy_turn_attack() -> void:
	
	if _middle_turn != false:
		return
	
	ENEMY_TURN = true
	player_mini.visible = true
	player_mini.z_index = 5
	player_mini.global_position = frame_parent.global_position
	player_mini.scale = Vector2(1.3, 1.3)
	player_mini_coll.disabled = false
	
	var enemy_proj = ENEMY.get_node("proj_area")
	var enemy_proj_texture = enemy_proj.get_node("proj_collision/projectiles")
	
	enemy_attack_create_vertical(enemy_proj, 0, randi_range(1, 2), randf_range(0.5, 1))
	enemy_attack_create_horizontal(enemy_proj, 0, randi_range(10, 13), randf_range(2, 2.5))

func enemy_attack_create_vertical(enemy_proj, index: int, max_index: int, delay):
	if index >= max_index and not ENEMY_TURN:
		print("Ход врага закончен")
		frame_to_start()
		return
	
	var enemy_proj_clone = enemy_proj.duplicate(15)
	var clone_coll = enemy_proj_clone.get_node("proj_collision")
	var clone_texture = clone_coll.get_node("projectiles")
	
	ENEMY.add_child(enemy_proj_clone)
	
	enemy_proj_clone.visible = true
	enemy_proj_clone.body_entered.connect(_on_enemy_proj_body_entered)
	enemy_proj_clone.z_index = 5
	var rand = randf_range(67, 90)
	
	enemy_proj_clone.global_position = Vector2(player_mini.global_position.x, rand)
	
	var tween = create_tween()
	
	var frame_global_top_left = frame.get_global_position()
	# Половина размера рамки
	var half_size = frame.size / 2
	# Центр рамки
	var frame_center = frame_global_top_left + half_size
	var frame_bottom = frame_center.y + half_size.y - 10
	
	clone_texture.play()
	tween.tween_property(enemy_proj_clone, "global_position:y", frame_bottom, 1)
	
	tween.tween_callback(func():
		clone_coll.disabled = true  # Отключаем коллизию ПОСЛЕ полета
	)
	
	tween.tween_property(enemy_proj_clone, "modulate:a", 0, 0.3)
	
	tween.finished.connect(func():
		enemy_proj_clone.queue_free()
		)
	if ENEMY_TURN:
		await get_tree().create_timer(delay).timeout
		await enemy_attack_create_vertical(enemy_proj, index + 1, max_index, randf_range(0.5, 1))

func enemy_attack_create_horizontal(enemy_proj, index: int, max_index: int, delay):
	if not ENEMY_TURN:
		print("Ход врага закончен")
		return
	
	var is_from = randi_range(0, 1)
	
	var enemy_proj_clone = enemy_proj.duplicate(15)
	var clone_coll = enemy_proj_clone.get_node("proj_collision")
	var clone_texture = clone_coll.get_node("projectiles")
	
	ENEMY.add_child(enemy_proj_clone)
	
	enemy_proj_clone.visible = true
	enemy_proj_clone.body_entered.connect(_on_enemy_proj_body_entered)
	enemy_proj_clone.z_index = 5
	
	
	var tween = create_tween()
	
	var frame_global_top_left = frame.get_global_position()

	# Половина размера рамки
	var half_size = frame.size / 2

	# Центр рамки
	var frame_center = frame_global_top_left + half_size
	
	var frame_left = frame_center.x - half_size.x + 10
	var frame_right = frame_center.x + half_size.x - 10
	
	if is_from == 0:
		enemy_proj_clone.rotation_degrees = -90
		var rand = randf_range(67, 90)
		enemy_proj_clone.global_position = Vector2(rand, player_mini.global_position.y)
		tween.tween_property(enemy_proj_clone, "global_position:x", frame_right, 1)
	elif is_from == 1:
		enemy_proj_clone.rotation_degrees = 90
		var rand = randf_range(567, 590)
		enemy_proj_clone.global_position = Vector2(rand, player_mini.global_position.y)
		tween.tween_property(enemy_proj_clone, "global_position:x", frame_left, 1)
		
	clone_texture.play()
	
	tween.tween_callback(func():
		clone_coll.disabled = true  # Отключаем коллизию ПОСЛЕ полета
	)
	
	tween.tween_property(enemy_proj_clone, "modulate:a", 0, 0.3)
	
	tween.finished.connect(func():
		enemy_proj_clone.queue_free()
		)
		
	if ENEMY_TURN:
		await get_tree().create_timer(delay).timeout
		await enemy_attack_create_horizontal(enemy_proj, index + 1, max_index, randf_range(2, 2.5))

func frame_to_start():
	player_mini_coll.disabled = true
	player_mini.visible = false
	ENEMY_TURN = false
	player_turn = true
	
	var tween = create_tween()	
	
	tween.parallel().tween_property(frame, "size", Vector2(435, 180), 0.5)
	
	tween.parallel().tween_property(frame, "position", -Vector2(435, 180) / 2, 0.5)
	
	await tween.finished
	setup_text()


func _on_enemy_proj_body_entered(body):
	if body == player_mini and not global_vars.invinc:
		global_vars.player_hp -= 1
		global_vars.invinc = true
		start_player_invincibility_effect(1.0, 0.1)


func start_player_invincibility_effect(duration: float, blink_speed: float) -> void:
	
	# Останавливаем предыдущий эффект, если он есть
	if has_node("InvincibilityTimer"):
		get_node("InvincibilityTimer").queue_free()
	
	var timer = Timer.new()
	timer.name = "InvincibilityTimer"
	timer.wait_time = blink_speed
	timer.one_shot = false
	add_child(timer)
	
	# Используем словарь для хранения изменяемых значений
	var state = {
		"elapsed": 0.0,
		"visible_state": false
	}
	
	# Сразу делаем невидимым
	player_mini_texture.modulate.a = 0.0
	
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(player_mini_texture):
			timer.queue_free()
			global_vars.invinc = false
			return
		
		state.elapsed += blink_speed
		
		# Проверяем, не истекло ли время
		if state.elapsed >= duration:
			# Конец эффекта - делаем полностью видимым
			player_mini_texture.modulate.a = 1.0
			timer.stop()
			timer.queue_free()
			global_vars.invinc = false
			return
		
		# Переключаем видимость
		state.visible_state = not state.visible_state
		player_mini_texture.modulate.a = 1.0 if state.visible_state else 0.0
	)
	
	timer.start()


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
	tween.parallel().tween_property(ENEMY, "position", target_enemy_pos, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)  # Изменяем позицию врага, чтобы он был сверху и был виден во время боя
	tween.parallel().tween_property(ENEMY, "scale", target_enemy_scale, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)   # Изменяем размер врага, чтобы его было видно
	
	
	# --- UI ИГРОКА --- #
	
	
	# Инициализация кнопок
	buttons.resize(2)
	
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
	tween.tween_property(buttons[0], "position", Vector2(160, 410), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(buttons[1], "position", Vector2(480, 410), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(hp_sprite, "position", Vector2(320, 410), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(frame, "modulate:a", 1.0, 0.1).set_trans(Tween.TRANS_LINEAR)
	
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
	
	if _middle_turn == true:
		# Ищем текст с id "victory"
		for dialogue in monologue_data["test_enemy"]:
			if str(dialogue["id"]) == "victory":  # ПРЕОБРАЗУЕМ В СТРОКУ
				text_to_show = dialogue["text"]
				break
		
		if text_to_show != "":
			start_typing_animation(text_to_show)
			return  # Выходим из функции
	
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
