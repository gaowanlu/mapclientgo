class_name TCPDemo extends Node

# TCP 对象
var tcp := StreamPeerTCP.new()

# 服务器配置
@export var tcpHost := "www.mfavant.xyz"
@export var tcpPort : int = 20027

# 是否已连接成功
var tcp_connected := false

func _ready() -> void:
	# 发起 TCP 连接（这里可以直接使用域名）
	var err := tcp.connect_to_host(tcpHost, tcpPort)

	if err != OK:
		push_error("TCP connect_to_host failed: %s" % err)
		return

	print("TCP connecting to: ", tcpHost, tcpPort)


func _process(_delta: float) -> void:
	# TCP 需要轮询状态
	tcp.poll()

	var status := tcp.get_status()

	match status:
		StreamPeerTCP.STATUS_CONNECTING:
			# 正在连接中
			return

		StreamPeerTCP.STATUS_CONNECTED:
			if not tcp_connected:
				tcp_connected = true
				print("TCP connected")

			_handle_connected()

		StreamPeerTCP.STATUS_ERROR, StreamPeerTCP.STATUS_NONE:
			if tcp_connected:
				print("TCP disconnected")
			tcp_connected = false


func _handle_connected() -> void:
	# 示例：按下 Enter 发送数据
	if Input.is_action_just_pressed("hit"):
		var msg := "hello server\n"
		var data := msg.to_utf8_buffer()

		# TCP 是流式写入
		var err := tcp.put_data(data)
		if err != OK:
			print("send failed:", err)

	# 接收数据（TCP 是流）
	while tcp.get_available_bytes() > 0:
		var recv := tcp.get_utf8_string(tcp.get_available_bytes())
		print("recv:", recv)
