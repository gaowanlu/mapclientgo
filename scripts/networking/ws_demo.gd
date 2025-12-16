class_name WSDemo extends Node

@export var websocket_url = "ws://www.mfavant.xyz:20025"
@export var userId = ""
@export var password = ""

const ProtoCmd = preload("res://scripts/proto_res/proto_cmd.gd")
const ProtoMessageHead = preload("res://scripts/proto_res/proto_message_head.gd")
const ProtoExample = preload("res://scripts/proto_res/proto_example.gd")

var protoPackage : ProtoMessageHead.ProtoPackage;
var protoCSReqLogin : ProtoExample.ProtoCSReqLogin;
var protoCSResLogin : ProtoExample.ProtoCSResLogin;

var already_try_login:bool = false

var socket = WebSocketPeer.new()

@warning_ignore("unused_signal")
signal signal_login_succ

func _ready() -> void:
	protoPackage = ProtoMessageHead.ProtoPackage.new();
	protoCSReqLogin = ProtoExample.ProtoCSReqLogin.new();
	protoCSReqLogin.set_userId(userId);
	protoCSReqLogin.set_password(password);
	protoCSResLogin = ProtoExample.ProtoCSResLogin.new();

	var err = socket.connect_to_url(websocket_url)
	if err == OK:
		print("Connecting to %s..." % websocket_url)

		# 等2秒后尝试发下消息
		# await get_tree().create_timer(2).timeout
		# Send data
		# print("> Sending test packet")
		# socket.send_text("Test packet")
	else:
		push_error("unable to connect.")
		set_process(false)

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	# Call this in `_process()` or `_physics_process()`.
	# Data transfer and state updates will only happen when calling this function.
	socket.poll()

	# get_ready_state() tells you what state the socket is in.
	var state = socket.get_ready_state()

	# `WebSocketPeer.STATE_OPEN` means the socket is connected and ready
	# to send and receive data.
	if state == WebSocketPeer.STATE_OPEN:
		if !already_try_login:
			print("进行登录请求")
			already_try_login = true;
			protoPackage.set_cmd(ProtoCmd.ProtoCmd.PROTO_CMD_CS_REQ_LOGIN);
			protoPackage.set_protocol(protoCSReqLogin.to_bytes());
			socket.send(protoPackage.to_bytes());

		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			var err = protoPackage.from_bytes(packet)
			if ProtoCmd.PB_ERR.NO_ERRORS == err:
				print("解包成功")
				print("cmd=",protoPackage.get_cmd())
				if protoPackage.get_cmd() == ProtoCmd.ProtoCmd.PROTO_CMD_CS_RES_LOGIN:
					print("PROTO_CMD_CS_RES_LOGIN")
					protoCSResLogin.from_bytes(protoPackage.get_protocol())
					print("sessionId=", protoCSResLogin.get_sessionId())
					signal_login_succ.emit(protoCSResLogin.get_sessionId())

	# `WebSocketPeer.STATE_CLOSING` means the socket is closing.
	# It is important to keep polling for a clean close.
	elif state == WebSocketPeer.STATE_CLOSING:
		pass

	# `WebSocketPeer.STATE_CLOSED` means the connection has fully closed.
	# It is now safe to stop polling.
	elif state == WebSocketPeer.STATE_CLOSED:
		# The code will be `-1` if the disconnection was not properly notified by the remote peer.
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false) # Stop processing 设置为false后_process将停止调用
