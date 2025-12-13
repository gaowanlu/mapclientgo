# 这个脚本定义了一个状态机“状态”的标准接口

# 将该脚本注册为全局类 NodeState
class_name NodeState extends Node

# 忽略“未使用信号”的编辑器警告
# 因为该信号是在子类或状态机中使用，而不是在本基类中
# 定义一个信号，用于“状态切换”
# 通常由当前状态发出，通知状态机切换到其他状态
@warning_ignore("unused_signal")
signal transition 

# 每一帧都会被状态机调用（非物理帧）
# delta：上一帧到当前帧的事件间隔（秒）
# 一般用于输入检测、UI更新、计时等非物理逻辑
func _on_process(_delta : float) -> void:
	pass

# 每一个物理帧都会被状态机调用（固定时间步）
# delta：固定的物理帧时间
# 一般用于角色移动、碰撞、速度计算等物理相关逻辑
func _on_physics_process(_delta : float) -> void:
	pass

# 用于判断是否需要切换到下一个状态
# 通常在这里检测条件，并满足时发出transition信号
# 例如：玩家按键、动画播放完成、AI条件满足等
func _on_next_transitions() -> void:
	pass

# 当状态“被切换进来”时调用一次
# 用于初始化状态：播放动画、重置变量、设置参数等
func _on_enter() -> void:
	pass

# 当状态“即将被切换出去”时调用一次
# 用于清理状态：停止动画、恢复参数、断开连接等
func _on_exit() -> void:
	pass
