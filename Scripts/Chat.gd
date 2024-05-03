extends CanvasLayer



func _ready() -> void:
	if Globals.is_networking:
		if not is_multiplayer_authority():
			self.visible = is_multiplayer_authority()
			return

	self.visible = true

@rpc("any_peer", "call_local")
func msg_rpc(username, data):
	
	if Globals.is_networking:
		if data.begins_with("/") and multiplayer.is_server():
			data = data.erase(0, 1)
			print(data)
			var expression = Expression.new()
			var error = expression.parse(data)
			if error != OK:
				$TextEdit.text = expression.get_error_text()
				return

			var result = expression.execute([], Globals.map)
			if result != null:
				$TextEdit.text = str(result)
	else:
		if data.begins_with("/"):
			data = data.erase(0, 1)
			print(data)
			var expression = Expression.new()
			var error = expression.parse(data)
			if error != OK:
				$TextEdit.text = expression.get_error_text()
				return

			var result = expression.execute([], Globals.map)
			if result != null:
				$TextEdit.text = str(result)	

	if data != "" or data != " ":
		$TextEdit.text +=  str(username, ": ", data, "\n")	

	$LineEdit.text = ""
	$TextEdit.scroll_vertical =  $TextEdit.get_line_height()

func _on_button_pressed():
	if Globals.is_networking:
		if not is_multiplayer_authority():
			return

		msg_rpc.rpc(Globals.username, $LineEdit.text)
	else:
		msg_rpc(Globals.username, $LineEdit.text)
