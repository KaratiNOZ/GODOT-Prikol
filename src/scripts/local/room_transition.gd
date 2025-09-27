extends Area2D

@export var target_scene : String = ""
@export var target_spawn_point : String = ""

func _ready():
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	if body.name == "player":
		global_vars.target_spawn_point = target_spawn_point
		sceneTransition.fade_to_scene(target_scene)
