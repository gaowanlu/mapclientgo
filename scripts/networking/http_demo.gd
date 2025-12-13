class_name HTTPDemo extends Node

@export var http_url = "https://mfavant.xyz"

var http_request : HTTPRequest

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	var json = JSON.stringify({
		userId = "1",
		password = "1"
	});

	var headers = ["Content-Type: application/json"]
	var err = http_request.request(http_url, headers, HTTPClient.METHOD_GET, json)
	if err != OK:
		push_error("在HTTP请求中发生了一个错误。")

@warning_ignore("unused_parameter")
func _on_request_completed(result, response_code, headers, body):
	print(body.get_string_from_utf8())
	#var json = JSON.parse_string(body.get_string_from_utf8())
	#print(json["name"])
	http_request.queue_free()
	http_request = null
