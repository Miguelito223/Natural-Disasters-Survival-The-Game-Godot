extends CanvasLayer

var msm

@rpc("any_peer", "call_local")
func msg_rpc(username, data):
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
