extends Node2D
@onready var ws_demo: WSDemo = $WSDemo
@onready var rich_text_label: RichTextLabel = $RichTextLabel

func _on_ready() -> void:
	ws_demo.signal_login_succ.connect(login_succ);
	rich_text_label.size = Vector2(500, 100);

func login_succ(sessionId: String)->void:
	rich_text_label.text = sessionId;
