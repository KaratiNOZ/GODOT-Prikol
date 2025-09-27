extends Node

#Кнопки для дебагинга
@export var debug_mode : bool = false

# Последнее направление игрока после отжатия кнопки ходьбы
# Почему то просто string не работает, нада писать String
@export var last_dir : String = ""

# Целевая точка спавна
@export var target_spawn_point : String = ""

# Булева приколябма может ли игрок ходить 
@export var can_move : bool = true

# delta координата игрока по Y
@export var player_y : float = 0.0

@export var npc_fade : bool = false

# Глобальное здоровье игрока
@export var player_hp : int = 3

# Неуязвимость
@export var invinc : bool = false
