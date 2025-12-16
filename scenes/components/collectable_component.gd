class_name CollectableComponent
extends Area2D

# 可采集的内容名称
@export var collectable_name: String

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		print("收集了 ", collectable_name)
		get_parent().queue_free();		
