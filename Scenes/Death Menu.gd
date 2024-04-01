extends CanvasLayer

func _ready():
	self.hide()

func _on_return_pressed():
	if not Globals.is_networking:
		get_tree().paused = false
		get_parent()._reset_player()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		self.hide()
	else:
		get_parent()._reset_player()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		self.hide()
		

func _on_exit_pressed():
	if Globals.is_networking:
		get_tree().get_multiplayer().multiplayer_peer.close()
	else:
		get_parent().get_parent().get_parent().get_node("Main Menu").show()
		get_parent().get_parent().queue_free()
