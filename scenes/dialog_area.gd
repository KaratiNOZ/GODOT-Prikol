extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("Игрок вошёл в зону диалога")

func _process(delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and Input.is_action_just_pressed("accept"):
			print("Начинаем диалог")
