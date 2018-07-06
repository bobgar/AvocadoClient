extends Control

onready var _client = get_node("Client")
onready var _log_dest = get_node("Panel/VBoxContainer/RichTextLabel")
onready var _line_edit = get_node("Panel/VBoxContainer/Send/LineEdit")
onready var _host = get_node("Panel/VBoxContainer/Connect/Host")

func _on_Send_pressed():
	if _line_edit.text == "":
		return

	Utils._log(_log_dest, "Sending data %s to %s" % [_line_edit.text, 0])
	_client.send_data(_line_edit.text, 0)
	_line_edit.text = ""

func _on_Connect_toggled( pressed ):
	if pressed:
		if _host.text != "":
			Utils._log(_log_dest, "Connecting to host: %s" % [_host.text])
			_client.connect_to_url(_host.text, [], false)
	else:
		_client.disconnect_from_host()
