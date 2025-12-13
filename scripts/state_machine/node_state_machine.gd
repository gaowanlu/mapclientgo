# 将该脚本注册为全局类 NodeStateMachine
# 该节点负责统一管理所有状态(NodeState)的切换与生命周期
class_name NodeStateMachine extends Node

# 在编辑器中暴露的变量：初始状态
# 只能指定继承自 NodeState 的节点
# 状态机启动后会自动进入该状态
@export var initial_node_state : NodeState

# 保存所有状态的字典
# key：状态节点名称（小写字符串）
# value：对应的NodeState节点
var node_states : Dictionary = {}

# 当前正在运行的状态对象
# 指向 node_states 中的某一个 NodeState
var current_node_state : NodeState
# 当前状态名称小写
# 主要用于调试或外部读取
var current_node_state_name : String

# 节点就绪时调用 用于初始化状态机
func _ready() -> void:
	# 遍历该状态机节点下的所有子节点
	for child in get_children():
		# 只处理继承自NodeState的子节点
		if child is NodeState:
			# 使用节点名（小写）作为key存入状态字典
			node_states[child.name.to_lower()] = child
			# 连接状态节点发出的 transition 信号
			# 当状态内部 emit transition 时，会调用 transition_to方法
			child.transition.connect(transition_to)
	
	# 如果在编辑器中设置了初始状态
	if initial_node_state:
		# 手动调用初始化状态的进入函数
		initial_node_state._on_enter()
		# 设置当前状态为初始状态
		current_node_state = initial_node_state
		# 保存当前状态名称
		current_node_state_name = current_node_state.name.to_lower()

# 每一帧调用（非物理帧）
# 用于处理输入、计时、UI等非物理逻辑
func _process(delta : float) -> void:
	if current_node_state:
		# 将 _process 调用转发给当前状态
		current_node_state._on_process(delta)

# 每一个物理帧调用（固定时间步）
# 用于角色移动，碰撞，物理相关逻辑
func _physics_process(delta: float) -> void:
	if current_node_state:
		# 调用当前状态的物理更新逻辑
		current_node_state._on_physics_process(delta)
		# 在物理帧中检测是否需要切换状态
		# 状态内部通常会在这里 emit transition信号
		current_node_state._on_next_transitions()

# 状态切换函数
# 由 NodeState 发出的 transition 信号触发
func transition_to(node_state_name : String) -> void:
	# 如果要切换的状态和当前状态相同，直接返回，防止重复进入同一个状态
	if node_state_name == current_node_state.name.to_lower():
		return
	# 从状态字典中查找目标状态
	var new_node_state = node_states.get(node_state_name.to_lower())
	# 如果目标状态不存在，直接返回
	if !new_node_state:
		return
	
	# 如果当前已经有状态在运行
	if current_node_state:
		# 调用当前状态的退出函数
		current_node_state._on_exit()
	# 调用新状态的进入函数
	new_node_state._on_enter()
	# 切换当前状态引用
	current_node_state = new_node_state
	# 更新当前状态名称
	current_node_state_name = current_node_state.name.to_lower()
	# 输出当前状态，方便调试
	print("Current State: ", current_node_state_name)
