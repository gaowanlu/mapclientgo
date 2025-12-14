extends StaticBody2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactable_component: InteractableComponent = $InteractableComponent

func _ready() -> void:
	interactable_component.interactable_activated.connect(on_interactable_activated)
	interactable_component.interactable_deactivated.connect(on_interactable_deactivated)
	collision_layer = 1 # 临时改变们的collision_layer

func on_interactable_activated() -> void:
	animated_sprite_2d.play("open_door")
	print("Player进入门")
	collision_layer = 2 # 临时改变们的collision_layer使得玩家能通过

func on_interactable_deactivated() -> void:
	animated_sprite_2d.play("close_door")
	print("Player离开门")
	collision_layer = 1 # 临时改变们的collision_layer
