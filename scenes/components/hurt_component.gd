class_name HurtComponent
extends Area2D

@export var tool:DataTypes.Tools = DataTypes.Tools.None

@warning_ignore("unused_signal")
signal signal_hurt

func _on_area_entered(area: Area2D) -> void:
	if !is_instance_of(area, HitComponent):
		print("非HitComponent碰到了HurtComponent")
		return
	var hit_component = area as HitComponent
	if tool == hit_component.current_tool:
		signal_hurt.emit(1) # 每次击打1ss滴血
