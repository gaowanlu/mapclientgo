class_name UDPDemo extends Node

var udp := PacketPeerUDP.new()
@export var udpHost = "你的域名"
@export var udpPort:int = 20027

var udp_ready = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 手动解析域名
	var ip_list := IP.resolve_hostname(udpHost, IP.TYPE_ANY)

	if ip_list.is_empty():
		push_error("DNS 解析失败: " + udpHost)
		return

	print("DNS resolved:", udpHost, "->", ip_list)

	# 使用 IP 连接
	var err := udp.connect_to_host(ip_list, udpPort)
	if err != OK:
		push_error("UDP connect failed: %s" % err)
		return

	udp_ready = true
	print("UDP ready:", ip_list, udpPort)

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if !udp_ready:
		return

	# 尝试发送数据
	udp.put_packet("hello server".to_utf8_buffer())
	# 接受数据
	while udp.get_available_packet_count() > 0:
		var data = udp.get_packet()
		print("recv:", data.get_string_from_utf8())
