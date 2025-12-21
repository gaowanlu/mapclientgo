class_name Rock extends Sprite2D

@onready var hurt_component: HurtComponent = $HurtComponent
@onready var damage_component: DamageComponent = $DamageComponent

var stone_scene = preload("res://scenes/objects/rocks/stone.tscn")

func _on_ready() -> void:
	# 注册受到伤害回调
	hurt_component.signal_hurt.connect(on_hurt)
	# 注册血量为零回调
	damage_component.signal_max_damaged_reached.connect(max_damaged_reached)

func on_hurt(hit_damage: int) -> void:
	print("rock受到伤害", hit_damage);
	# 将收到的伤害传给damage_component
	damage_component.apply_damage(hit_damage);
	material.set_shader_parameter("shake_intensity", 0.3);
	await get_tree().create_timer(0.5).timeout
	material.set_shader_parameter("shake_intensity", 0.0);

func max_damaged_reached() -> void:
	call_deferred("add_stone_scene");
	print("rock的血量被打完了")
	queue_free(); # 删除自己这个节点

func _on_tree_exited() -> void:
	print("rock节点离开了树")

func add_stone_scene()->void:
	var stone_scene_instance = stone_scene.instantiate() as Node2D
	# rock成stone放在原来树的位置
	stone_scene_instance.global_position = global_position;
	get_parent().add_child(stone_scene_instance);
