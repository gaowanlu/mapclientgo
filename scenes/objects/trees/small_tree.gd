class_name SmallTree
extends Sprite2D

@onready var hurt_component: HurtComponent = $HurtComponent
@onready var damage_component: DamageComponent = $DamageComponent

var tree_log_scene = preload("res://scenes/objects/trees/tree_log.tscn")

func _on_ready() -> void:
	# 注册受到伤害回调
	hurt_component.signal_hurt.connect(on_hurt)
	# 注册血量为零回调
	damage_component.signal_max_damaged_reached.connect(max_damaged_reached)

func on_hurt(hit_damage: int) -> void:
	print("小树受到伤害", hit_damage);
	# 将收到的伤害传给damage_component
	damage_component.apply_damage(hit_damage);

func max_damaged_reached() -> void:
	call_deferred("add_tree_log_scene");
	print("小树的血量被打完了")
	queue_free(); # 删除自己这个节点

func _on_tree_exited() -> void:
	print("小树节点离开了树")

func add_tree_log_scene()->void:
	var tree_log_scene_instance = tree_log_scene.instantiate() as Node2D
	# 树变成原木放在原来树的位置
	tree_log_scene_instance.global_position = global_position;
	get_parent().add_child(tree_log_scene_instance);
