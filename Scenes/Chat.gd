extends CanvasLayer


var msm

@rpc("any_peer", "call_local")
func msg_rpc(username, data):
	$TextEdit.text +=  str(username, ": ", data, "\n")

func _on_button_pressed():
	msg_rpc.rpc(Globals.username, $LineEdit.text)
