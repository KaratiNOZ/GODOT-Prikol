extends Node2D

# ============================================================================
# УЗЛЫ СЦЕНЫ
# ============================================================================
var heart: Sprite2D          # Спрайт сердца
var label: Label             # Основной текст
var name_label: Label        # Поле для ввода имени
var accept: Label            # Кнопка "Да"
var refuse: Label            # Кнопка "Нет"

# ============================================================================
# СОСТОЯНИЯ И ПЕРЕМЕННЫЕ
# ============================================================================
var current_text: int = 8           # Текущий индекс текста в последовательности
var my_choice: int = -1             # Выбор игрока (-1 = нет выбора, 0 = да, 1 = нет)
var my_name: String = ""            # Имя игрока

# Флаги состояния
var is_inputting: bool = false      # Режим ввода имени
var is_choicing: bool = false       # Режим выбора (да/нет)

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
	"гей": "Мне кажется не стоит",
	"хуесос": "Я бы не стал себя так называть",
	"ниггер": "Боюсь ты ошибся на одну букву",
	"гитлер": "Ты сам знаешь кто-он...",
	"сука": "Ну можно и по-культурнее что-то",
	"тварь": "Как будто слишком низкая самооценка",
	"мразь": "Такое себе имя",
	"враг": "...",
	"гандопляс": "Тотемович, ну кто-ж знал что у них на вард на хэгэ",
}

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
		await get_tree().create_timer(4.0).timeout
		heart_beat(current_text)  # Запускаем биение сердца
		await get_tree().create_timer(4.0).timeout
		next_text(current_text)   # Запускаем показ текста

# Инициализация ссылок на узлы сцены
func _initialize_nodes() -> void:
	var parent: Node = get_parent()
	heart = parent.get_node("heart")
	label = parent.get_node("label_parent/label")
	name_label = label.get_parent().get_node("name_label")
	accept = parent.get_node("y/accept")
	refuse = parent.get_node("n/refuse")

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
		
		KEY_ENTER:
			# Завершаем ввод
			if name_label.text.length() > 0:
				var input_lower: String = name_label.text.to_lower()
				
				# Проверяем на запрещённые слова
				if input_lower in BAD_WORDS:
					label.text = BAD_WORDS[input_lower]
				elif input_lower ==  "pigeousguy":
					OS.alert("Думаю, тебе и мне стоит о нём забыть", "1746")
					get_tree().quit(1746)
				else:
					is_inputting = false
		
		KEY_SPACE:
			# Пробелы не добавляем
			pass
		
		_:
			# Добавляем символ если он допустимый
			if event.unicode != 0:
				var character: String = char(event.unicode)
				if character in ALLOWED_CHARS:
					name_label.text += character

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
		pass
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
	
	# Получаем длительность для текущего индекса
	var duration: float = DURATIONS[text_index] if text_index < DURATIONS.size() else 0.30
	
	# Создаём анимацию биения
	tween_heart = create_tween()
	tween_heart.tween_property(heart, "modulate:a", 1.0, duration)       # Появление
	tween_heart.tween_property(heart, "modulate:a", 0.0, duration + 0.3) # Исчезновение
	tween_heart.tween_interval(0.5)                                       # Пауза
	
	await tween_heart.finished
	
	# Рекурсивный вызов для следующего биения
	heart_beat(current_text)

# ============================================================================
# ПОСЛЕДОВАТЕЛЬНОСТЬ ТЕКСТОВ
# ============================================================================
func next_text(text_index: int) -> void:
	# Если все тексты показаны, переходим к вводу имени
	if current_text > 7:
		name_input()
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
		2: return "БИЕНИЕ"
		3: return "ДЫХАНИЕ"
		4: return "МЫСЛЬ"
		5: return "ТЕПЕРЬ МЫ СВЯЗАНЫ"
		6: return "НО КТО Я ?"
		7: return "КЕМ Я БУДУ ?"
		_: return "Я ЕСТЬ"

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
