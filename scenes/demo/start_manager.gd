extends Node2D

# ============================================================================
# УЗЛЫ СЦЕНЫ
# ============================================================================
var heart: Sprite2D          # Спрайт сердца
var label: Label             # Основной текст
var mind_wall: Sprite2D      # Спрайт стены
var inevitability: Sprite2D
var name_label: Label        # Поле для ввода имени
var accept: Label            # Кнопка "Да"
var refuse: Label            # Кнопка "Нет"

# ============================================================================
# СОСТОЯНИЯ И ПЕРЕМЕННЫЕ
# ============================================================================
var current_text: int = 0           # Текущий индекс текста в последовательности
var my_choice: int = -1             # Выбор игрока (-1 = нет выбора, 0 = да, 1 = нет)
var fade_alpha: float = 1.0
var arr_wall_clones: Array = []
var my_name: String = ""            # Имя игрока

# Флаги состояния
var is_inputting: bool = false      # Режим ввода имени
var is_choicing: bool = false       # Режим выбора (да/нет)
var is_beating: bool = true
var is_scattering: bool = false

# ============================================================================
# ТВИНЫ (АНИМАЦИИ)
# ============================================================================
var tween_label: Tween = null       # Твин для анимации текста
var tween_heart: Tween = null       # Твин для биения сердца
var y_tween: Tween = null           # Твин для кнопки "Да"
var n_tween: Tween = null           # Твин для кнопки "Нет"

# ============================================================================
# КОНСТАНТЫ
# ============================================================================
# Разрешённые символы для ввода имени
const ALLOWED_CHARS: String = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюяABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz "

# Словарь запрещённых имён с ответами
const BAD_WORDS: Dictionary = {
	"пидор": "Вот оно чё михалыч",
	"гитлер": "Ты сам знаешь кто-он...",
	"враг": "...",
	"гандопляс": "Тотемович, ну кто-ж знал что у них на вард на хэгэ",
	"свиньяиванов": "неадекват свинья"
}

# Массив с его именем
const GBUTEC: Array = [
	"pigeousguy",
	"piguy",
	"пигеусгай",
	"пигеус",
	"пигай",
]

# Цвета
const COLOR_RED: Color = Color("#cb1846")
const COLOR_WHITE: Color = Color.WHITE

# ============================================================================
# ИНИЦИАЛИЗАЦИЯ
# ============================================================================
func _ready() -> void:
	# Получаем ссылки на узлы сцены
	_initialize_nodes()
	
	# Если все узлы найдены, запускаем последовательность
	if heart and label:
		heart.modulate.a = 0.0  # Делаем сердце прозрачным
		#await get_tree().create_timer(4.0).timeout
		heart_beat(current_text)  # Запускаем биение сердца
		#await get_tree().create_timer(4.0).timeout
		next_text(current_text)   # Запускаем показ текста
		#await get_tree().create_timer(8.0).timeout
		start_text_scatter()
		mind_wall_anim() # Запускаем анимацию с боков

# Инициализация ссылок на узлы сцены
func _initialize_nodes() -> void:
	var parent: Node = get_parent()
	heart = parent.get_node("heart")
	label = parent.get_node("label_parent/label")
	name_label = label.get_parent().get_node("name_label")
	accept = parent.get_node("y/accept")
	refuse = parent.get_node("n/refuse")
	mind_wall = parent.get_node("mind_wall")
	inevitability = parent.get_node("inevitability")

# ============================================================================
# ОБРАБОТКА ВВОДА
# ============================================================================
func _input(event: InputEvent) -> void:
	# Игнорируем события мыши
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		return
	
	# Обработка ввода имени
	if is_inputting:
		_handle_name_input(event)
	
	# Обработка выбора (да/нет)
	if is_choicing:
		_handle_choice_input(event)

# Обработка ввода имени
func _handle_name_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_pressed()):
		return
	
	match event.keycode:
		KEY_BACKSPACE:
			# Удаляем последний символ
			if name_label.text.length() > 0:
				name_label.text = name_label.text.substr(0, name_label.text.length() - 1)
				"""
				for wall_clone in arr_wall_clones:
							if is_instance_valid(wall_clone):
								var flash_tween = create_tween()
								var current_alpha = wall_clone.self_modulate.a
								flash_tween.parallel().tween_property(wall_clone, "self_modulate:a", 0.1, 0.1)
								await get_tree().create_timer(0.009).timeout
				"""
		KEY_ENTER:
			# Завершаем ввод
			if name_label.text.length() > 0:
				var input_lower: String = name_label.text.to_lower()
				
				# Проверяем на запрещённые слова
				if input_lower in BAD_WORDS:
					label.text = BAD_WORDS[input_lower]
				elif input_lower in GBUTEC:
					OS.alert("11010000 10011111 11010000 10111110 100000 11010000 10110101 11010000 10110011 11010000 10111110 100000 11010001 10000010 11010000 10110010 11010000 10111110 11010001 10000000 11010000 10110101 11010000 10111101 11010000 10111000 11010001 10001110 100000 11010000 10110101 11010001 10000001 11010001 10000010 11010001 10001100 100000 11010000 10111111 11010000 10111110 11010000 10110010 11010000 10110101 11010001 10000000 11010000 10111000 11010000 10110101 100000 11010000 10111111 11010001 10000000 11010000 10111110 100000 11010000 10111100 11010000 10110101 11010001 10000001 11010001 10000010 11010000 10111110 101100 100000 11010000 10110011 11010000 10110100 11010000 10110101 100000 11010001 10000001 11010001 10000010 11010001 10000000 11010000 10110000 11010000 10110100 11010000 10110000 11010001 10001110 11010001 10000010", "0x001746")
					OS.alert("11010000 10011111 11010001 10000000 11010000 10111110 11010000 10110001 11010001 10001100 11010001 10010001 11010001 10000010 100000 11010001 10000111 11010000 10110000 11010001 10000001 101100 100000 11010000 10111100 11010001 10001011 100000 11010000 10110010 11010001 10000001 11010000 10110101 100000 11010001 10000010 11010000 10110000 11010000 10111100 100000 11010000 10110001 11010001 10000011 11010000 10110100 11010000 10110101 11010000 10111100","0x001746")
					get_tree().quit(1746)
				else:
					is_inputting = false
					my_name = name_label.text
		
		KEY_SPACE:
			# Пробелы не добавляем
			pass
		
		_:
			# Добавляем символ если он допустимый
			if event.unicode != 0 and name_label.text.length() < 20:
				var character: String = char(event.unicode)
				if character in ALLOWED_CHARS:
					name_label.text += character
					"""
					for wall_clone in arr_wall_clones:
						if is_instance_valid(wall_clone):
							var flash_tween = create_tween()
							var current_alpha = wall_clone.self_modulate.a
							flash_tween.parallel().tween_property(wall_clone, "self_modulate:a", 0.1, 0.1)
							await get_tree().create_timer(0.009).timeout
					"""
# Обработка выбора (да/нет)
func _handle_choice_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_pressed()):
		return
	
	var old_choice: int = my_choice
	
	# Навигация по выбору
	if event.keycode == KEY_LEFT or event.keycode == KEY_A:
		my_choice = 0  # Выбор "Да"
	elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
		my_choice = 1  # Выбор "Нет"
	elif event.keycode == KEY_ENTER and my_choice != -1:
		# Подтверждение выбора
		_confirm_choice()
	
	# Обновляем подсветку только если выбор изменился
	if my_choice != old_choice and my_choice >= 0:
		_update_choice_highlight()

# Подтверждение выбора игрока
func _confirm_choice() -> void:
	if my_choice == 0:
		# Выбрано "Да" - продолжаем игру
		await input_confirmed()
	elif my_choice == 1:
		# Выбрано "Нет" - возвращаемся к вводу имени
		await _restart_name_input()

# Обновление подсветки кнопок выбора
func _update_choice_highlight() -> void:
	# Останавливаем все активные твины
	_stop_choice_tweens()
	
	match my_choice:
		0:  # Выбрано "Да"
			# Refuse плавно в белый
			var reset_n: Tween = create_tween()
			reset_n.tween_property(refuse, "modulate", COLOR_WHITE, 0.4)
			
			# Accept плавно в красный
			y_tween = create_tween()
			y_tween.tween_property(accept, "modulate", COLOR_RED, 0.4)
			
		1:  # Выбрано "Нет"
			# Accept плавно в белый
			var reset_y: Tween = create_tween()
			reset_y.tween_property(accept, "modulate", COLOR_WHITE, 0.4)
			
			# Refuse плавно в красный
			n_tween = create_tween()
			n_tween.tween_property(refuse, "modulate", COLOR_RED, 0.4)

# Остановка твинов кнопок выбора
func _stop_choice_tweens() -> void:
	if y_tween:
		y_tween.kill()
	if n_tween:
		n_tween.kill()

# ============================================================================
# АНИМАЦИЯ СЕРДЦА
# ============================================================================
func heart_beat(text_index: int) -> void:
	# Длительности биения для каждого этапа
	const DURATIONS: Array[float] = [0.95, 0.90, 0.85, 0.75, 0.65, 0.55, 0.45, 0.35]
	const FADE_STEP: float = 0.1  # Шаг затухания
	
	# Получаем длительность для текущего индекса
	var duration: float = DURATIONS[text_index] if text_index < DURATIONS.size() else 0.30
	
	if is_beating:
		# Сбрасываем затухание при активном биении
		fade_alpha = 1.0
		
		# Создаём анимацию биения
		tween_heart = create_tween()
		tween_heart.tween_property(heart, "modulate:a", 1.0, 0.15)       # Появление
		tween_heart.tween_property(heart, "modulate:a", 0.0, duration + 0.15) # Исчезновение
		tween_heart.tween_interval(duration)                                       # Пауза
		
		await tween_heart.finished
	else:
		# Уменьшаем максимальную прозрачность с каждой итерацией
		fade_alpha = max(0.0, fade_alpha - FADE_STEP)
		
		# Создаём анимацию биения с затуханием
		tween_heart = create_tween()
		tween_heart.tween_property(heart, "modulate:a", fade_alpha, duration)       # Появление до fade_alpha
		tween_heart.tween_property(heart, "modulate:a", 0.0, duration + 0.3)        # Исчезновение
		tween_heart.tween_interval(duration)                                              # Пауза
		
		await tween_heart.finished
	
	# Рекурсивный вызов для следующего биения
	heart_beat(current_text)

func mind_wall_anim() -> void:
	if is_scattering == false:
		return
	var parent: Node2D = get_parent()
	
	var wall_clone_left = mind_wall.duplicate(15)
	parent.add_child(wall_clone_left)
	wall_clone_left.flip_v = bool(randi() % 2)
	wall_clone_left.self_modulate.a = 0.09
	
	var wall_clone_right = mind_wall.duplicate(15)
	parent.add_child(wall_clone_right)
	wall_clone_right.flip_v = bool(randi() % 2)
	wall_clone_right.self_modulate.a = 0.09
	wall_clone_right.flip_h = true
	
	"""
	var inevitability_clone = inevitability.duplicate(15)
	inevitability_clone.self_modulate.a = 0.02
	parent.add_child(inevitability_clone)
	"""
	arr_wall_clones.append(wall_clone_left)
	arr_wall_clones.append(wall_clone_right)
	
	var wall_width = mind_wall.texture.get_width()
	
	# Симметричные начальные позиции
	wall_clone_left.position.x = 0 - wall_width
	wall_clone_right.position.x = 640 + wall_width
	
	var clone_tween = create_tween()
	var start_y = wall_clone_left.position.y
	var amplitude = 10.0  # Высота волны
	var frequency = 2.0   # Частота колебаний
	
	clone_tween.set_parallel(true)
	
	"""
	clone_tween.tween_property(inevitability_clone, "scale:x", 1.0, 7.0)
	clone_tween.tween_property(inevitability_clone, "scale:y", 1.0, 7.0)
	clone_tween.tween_property(inevitability_clone, "rotation_degrees", 360, 20.0)
	clone_tween.tween_property(inevitability_clone, "self_modulate:a", 0.0, 15.0)
	"""
	
	clone_tween.tween_property(wall_clone_left, "position:x", wall_width, 9.0)
	clone_tween.tween_method(func(progress):
		var y_offset = sin(progress * frequency * TAU) * amplitude
		wall_clone_left.position.y = start_y + y_offset
	, 0.0, 1.0, 9.0)
	clone_tween.tween_property(wall_clone_right, "position:x", 640 - wall_width, 9.0)
	
	clone_tween.tween_property(wall_clone_left, "self_modulate:a", 0.0, 12.0)
	clone_tween.tween_property(wall_clone_right, "self_modulate:a", 0.0, 12.0)
	
	await get_tree().create_timer(1.0).timeout
	mind_wall_anim()
	
	await clone_tween.finished
	
	arr_wall_clones.erase(wall_clone_left)
	arr_wall_clones.erase(wall_clone_right)
	"""
	inevitability_clone.queue_free()
	"""
	wall_clone_left.queue_free()
	wall_clone_right.queue_free()

# Функция для запуска эффекта разлетания
func start_text_scatter() -> void:
	is_scattering = true
	text_scatter_loop()

# Функция для остановки эффекта
func stop_text_scatter() -> void:
	is_scattering = false

# Основной цикл создания разлетающихся клонов
func text_scatter_loop() -> void:
	while is_scattering:
		create_scatter_clone()
		await get_tree().create_timer(0.5).timeout

# Создание одного клона с анимацией разлетания
func create_scatter_clone() -> void:
	# Создаём клон label
	var label_clone: Label = label.duplicate(15)
	label.get_parent().add_child(label_clone)
	
	# Копируем текущие параметры
	label_clone.text = label.text
	label_clone.self_modulate.a = label.self_modulate.a - 0.9
	
	var accept_clone: Label = accept.duplicate(15)
	accept.get_parent().add_child(accept_clone)
	
	# Копируем текущие параметры
	accept_clone.text = accept.text
	accept_clone.self_modulate.a = accept.self_modulate.a - 0.8
	
	var refuse_clone: Label = refuse.duplicate(15)
	refuse.get_parent().add_child(refuse_clone)
	
	# Копируем текущие параметры
	refuse_clone.text = refuse.text
	refuse_clone.self_modulate.a = refuse.self_modulate.a - 0.8
	
	var clone_tween = create_tween()
	
	clone_tween.set_parallel(true)
	clone_tween.tween_property(label_clone, "scale:x", 2.0, 2.0)
	clone_tween.tween_property(label_clone, "scale:y", 2.0, 2.0)
	clone_tween.tween_property(label_clone, "position", label_clone.position - (label_clone.size / 2.0), 2.0)
	clone_tween.tween_property(label_clone, "self_modulate:a", 0.0, 1.5)
	
	clone_tween.tween_property(accept_clone, "scale:x", 2.0, 2.0)
	clone_tween.tween_property(accept_clone, "scale:y", 2.0, 2.0)
	clone_tween.tween_property(accept_clone, "position", accept_clone.position - (accept_clone.size / 2.0), 2.0)
	clone_tween.tween_property(accept_clone, "self_modulate:a", 0.0, 1.5)
	
	clone_tween.tween_property(refuse_clone, "scale:x", 2.0, 2.0)
	clone_tween.tween_property(refuse_clone, "scale:y", 2.0, 2.0)
	clone_tween.tween_property(refuse_clone, "position", refuse_clone.position - (refuse_clone.size / 2.0), 2.0)
	clone_tween.tween_property(refuse_clone, "self_modulate:a", 0.0, 1.5)
	await clone_tween.finished
	
	label_clone.queue_free()

# ============================================================================
# ПОСЛЕДОВАТЕЛЬНОСТЬ ТЕКСТОВ
# ============================================================================
func next_text(text_index: int) -> void:
	# Если все тексты показаны, переходим к вводу имени
	if current_text == 8:
		name_input()
		return
	if current_text == 12:
		is_beating = false
		stop_text_scatter()
		
		return
	
	# Получаем текст для текущего индекса
	var current_message: String = _get_text_by_index(text_index)
	label.text = current_message
	
	# Подготовка к анимации
	label.modulate.a = 0.0
	label.visible_ratio = 0.0
	
	# Создаём анимацию появления текста
	tween_label = create_tween()
	# Появление прозрачности и печать текста одновременно
	tween_label.parallel().tween_property(label, "modulate:a", 1.0, 1.0)
	tween_label.parallel().tween_property(label, "visible_ratio", 1.0, float(label.text.length() * 0.10))
	# Пауза после появления
	tween_label.tween_interval(float(label.text.length() * 0.17))
	# Исчезновение текста
	tween_label.tween_property(label, "modulate:a", 0.0, 2.0)
	# Финальная пауза
	tween_label.tween_interval(1.0)
	
	await tween_label.finished
	
	# Переход к следующему тексту
	current_text += 1
	next_text(current_text)

# Получение текста по индексу
func _get_text_by_index(text_index: int) -> String:
	match text_index:
		0: return "РАЗВЕ ЭТО НЕ ПРЕКРАСНО"
		1: return "ВИДЕТЬ ЭТО ?"
		2: return "ЧУДО"
		3: return "МГНОВЕНИЕ"
		4: return "МЫСЛЬ"
		5: return "ТЕПЕРЬ МЫ СВЯЗАНЫ"
		6: return "НО КТО Я ?"
		7: return "КЕМ Я БУДУ ?"
		9: return "ХОРОШО"
		10: return "ТЕПЕРЬ Я"
		11: return my_name.to_upper()
		_: return "ЭТОТ МОЁ"

# ============================================================================
# ВВОД ИМЕНИ
# ============================================================================
func name_input() -> void:
	label.text = "ВВЕДИ МОЁ ИМЯ"
	
	# Подготовка к анимации
	label.modulate.a = 0.0
	label.visible_ratio = 0.0
	
	# Анимация появления текста
	tween_label = create_tween()
	tween_label.parallel().tween_property(label, "modulate:a", 1.0, 1.0)
	tween_label.parallel().tween_property(label, "visible_ratio", 1.0, float(label.text.length() * 0.10))
	tween_label.tween_interval(1.5)
	# Перемещение текста вверх
	tween_label.tween_property(label, "position:y", -49.5, 1.5)
	
	await tween_label.finished
	
	# Запускаем цикл ввода имени
	await _input_loop()

# Цикл ввода имени и подтверждения
func _input_loop() -> void:
	# Включаем режим ввода
	is_inputting = true
	
	# Ждём пока игрок не завершит ввод
	while is_inputting:
		await get_tree().create_timer(0.05).timeout
	
	# Переходим к подтверждению
	await _show_confirmation()

# Показ экрана подтверждения
func _show_confirmation() -> void:
	# Убираем текущий текст
	tween_label = create_tween()
	tween_label.tween_property(label, "modulate:a", 0.0, 1.0)
	await tween_label.finished
	
	# Подготовка нового текста
	label.visible_ratio = 0.0
	label.text = "Я УВЕРЕН ?"
	
	# Показываем вопрос
	tween_label = create_tween()
	tween_label.parallel().tween_property(label, "modulate:a", 1.0, 1.0)
	tween_label.parallel().tween_property(label, "visible_ratio", 1.0, float(label.text.length() * 0.10))
	await tween_label.finished
	
	# Показываем кнопки выбора
	await _show_choice_buttons()
	
	# Включаем режим выбора
	is_choicing = true
	
	# Ждём пока игрок не сделает выбор
	while is_choicing:
		await get_tree().create_timer(0.05).timeout

# Показ кнопок выбора (да/нет)
func _show_choice_buttons() -> void:
	# Подготовка кнопок
	accept.modulate.a = 0.0
	refuse.modulate.a = 0.0
	accept.visible_ratio = 0.0
	refuse.visible_ratio = 0.0
	
	# Анимация появления кнопок
	var choice_tween: Tween = create_tween()
	choice_tween.parallel().tween_property(accept, "modulate:a", 1.0, 0.9)
	choice_tween.parallel().tween_property(refuse, "modulate:a", 1.0, 0.9)
	choice_tween.parallel().tween_property(accept, "visible_ratio", 1.0, 0.9)
	choice_tween.parallel().tween_property(refuse, "visible_ratio", 1.0, 0.9)
	
	await choice_tween.finished

# Перезапуск ввода имени (когда игрок выбрал "Нет")
func _restart_name_input() -> void:
	# Останавливаем режим выбора
	is_choicing = false
	my_choice = -1
	
	# Плавно убираем все элементы
	var fade_out: Tween = create_tween()
	fade_out.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	fade_out.parallel().tween_property(accept, "modulate:a", 0.0, 0.9)
	fade_out.parallel().tween_property(refuse, "modulate:a", 0.0, 0.9)
	await fade_out.finished
	
	# Сбрасываем состояния
	label.visible_ratio = 0.0
	accept.visible_ratio = 0.0
	refuse.visible_ratio = 0.0
	
	# Возвращаем кнопкам белый цвет
	accept.modulate = COLOR_WHITE
	refuse.modulate = COLOR_WHITE
	
	# Показываем текст для ввода
	label.text = "ИСПРАВЬ МОЁ ИМЯ"
	label.modulate.a = 0.0
	
	tween_label = create_tween()
	tween_label.parallel().tween_property(label, "modulate:a", 1.0, 1.0)
	tween_label.parallel().tween_property(label, "visible_ratio", 1.0, float(label.text.length() * 0.10))
	await tween_label.finished
	
	# Запускаем повторный цикл ввода
	await _input_loop()

# Ввод имени подтверждён
func input_confirmed() -> void:
	# Останавливаем режим выбора
	is_choicing = false
	my_choice = -1
	
	# Плавно убираем все элементы
	var fade_out: Tween = create_tween()
	fade_out.parallel().tween_property(label, "modulate:a", 0.0, 2.0)
	fade_out.parallel().tween_property(accept, "modulate:a", 0.0, 2.0)
	fade_out.parallel().tween_property(refuse, "modulate:a", 0.0, 2.0)
	fade_out.parallel().tween_property(name_label, "modulate:a", 0.0, 2.0)
	await fade_out.finished
	
	# Сбрасываем состояния
	label.visible_ratio = 0.0
	label.position.y = -11.5
	
	current_text = 9
	next_text(current_text)
