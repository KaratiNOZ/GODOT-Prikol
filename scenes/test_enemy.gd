extends CharacterBody2D

# Всё что связано с энеми
var ENEMY = self
var ENEMY_HP = 1500
var ENEMY_WALK_SPEED = 90

var IS_CHASING = false


# Всё что связано с врагом
var player = null
var in_fight = false

func _ready() -> void:
	player = get_tree().current_scene.get_node("player") # Получаем игрока
	$area_vision.body_entered.connect(_on_body_entered)  # Если игрок зашел в зону видимости
	$area_vision.body_exited.connect(_on_body_exited)    # Если игрок вышел из зоны видимости

# --- Сигналы для Area2D --- #
func _on_body_entered(body):
	IS_CHASING = true

func _on_body_exited(body):
	IS_CHASING = false
# --- ================== --- #

# Для работы с физикой
func _physics_process(delta: float) -> void:
	if not IS_CHASING or in_fight:
		return
	
	var dir = (player.position - position).normalized()
	var collision = move_and_collide(dir * ENEMY_WALK_SPEED * delta)
	
	if collision and collision.get_collider() == player:
		in_fight = true
		IS_CHASING = false
		global_vars.can_move = false
		await get_tree().create_timer(0.2).timeout
		setup_fight()
	
func _process(delta: float) -> void:
	# Нужно чтобы было ощущение 3D 0_o
	if not in_fight:
		if global_vars.player_y > position.y + 5:
			self.z_index = 0              # <- 100% надо юзать self, иначе работать не будет!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		else:
			self.z_index = 1              # <- тоже

func setup_fight() -> void:
	var fight_background = ColorRect.new()               # Создание задника
	get_tree().current_scene.add_child(fight_background) # Сразу добавляем его в сцену или уже другими словами добавляем в узел home_living который вот слева тут, в левом верхнем углу его можно видеть если ты открыл эту сцену через Godot Engine Stable Win64 . ExE
	
	# Настройка задника
	fight_background.color = Color.BLACK       # Цвет заливки
	fight_background.z_index = 1               # его z индекс
	fight_background.modulate.a = 0.0          # начальная прозрачность
	fight_background.size = Vector2(640, 480)  # задаём размер
	fight_background.position = Vector2(0, 0)  # задаём позицию
	
	# Создаем твин для управлением анимации
	var tween = create_tween()
	tween.tween_property(fight_background,   "modulate:a",     1.0,         0.2) # Изменяем прозрачность за 0.2 секунды
						# ^ это цель        это параметр     значение    это время
	ENEMY.z_index = 2
