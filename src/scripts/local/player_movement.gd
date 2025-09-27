extends CharacterBody2D

@export var speed = 250

var input_direction

func _ready() -> void:
	# Устанавливаем последнее направление при загрузке сцены
	var player_sprites = $player_sprites
	if global_vars.last_dir != "":
		player_sprites.play(global_vars.last_dir)
	
	if global_vars.target_spawn_point != "":
		var spawn_point = get_tree().current_scene.find_child(global_vars.target_spawn_point)
		if spawn_point:
			self.position = spawn_point.position
	global_vars.target_spawn_point = ""

func get_input():
	
	if not global_vars.can_move:
		input_direction = Vector2.ZERO
		velocity = Vector2.ZERO
		return
	
	#Получаем вектор направление через клавишы стрелок и устанавлием локальную переменную скорости
	input_direction = Input.get_vector("arrow_left", "arrow_right",  "arrow_up", "arrow_down")
	velocity = input_direction * speed


func _physics_process(delta: float) -> void:
	get_input()
	move_and_slide()
	player_anims()
	global_vars.player_y = self.position.y


func player_anims():
	# Анимация и сохранение последнего направление игрока -_- + изменения размера коллайдера
	var player_sprites = $player_sprites
	var plr_main_collision = $plr_main_collision
	
	if input_direction.x < 0:
		plr_main_collision.shape.size.x = 28.0
		player_sprites.play("left")
		global_vars.last_dir = "left"
		
	elif input_direction.x > 0:
		plr_main_collision.shape.size.x = 28.0
		player_sprites.play("right")
		global_vars.last_dir = "right"
		
	elif input_direction.y > 0:
		plr_main_collision.shape.size.x = 46.0
		player_sprites.play("front")
		global_vars.last_dir = "front"
		
	elif input_direction.y < 0:
		plr_main_collision.shape.size.x = 46.0
		player_sprites.play("back")
		global_vars.last_dir = "back"
		
	else:
		player_sprites.play(global_vars.last_dir)
