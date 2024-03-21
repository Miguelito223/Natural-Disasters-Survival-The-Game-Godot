extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$Menu.show()
	$Multiplayer.hide()
	$Settings.hide()


	$Multiplayer/username.text = Globals.username
	$Multiplayer/ip.text = Globals.ip
	$Multiplayer/port.text = str(Globals.port)
	$Settings/fps.button_pressed = Globals.FPS
	$Settings/vsync.button_pressed = Globals.vsync
	$Settings/antialiasing.button_pressed = Globals.antialiasing


func _on_ip_text_changed(new_text:String):
	Globals.ip = new_text


func _on_port_text_changed(new_text:String):
	Globals.port = int(new_text)


func _on_join_pressed():
	Globals.hostwithip(Globals.ip, Globals.port)


func _on_host_pressed():
	Globals.hostwithport(Globals.port)


func _on_play_pressed():
	$Menu.hide()
	$Multiplayer.show()
	$Settings.hide()


func _on_settings_pressed():
	$Menu.hide()
	$Multiplayer.hide()
	$Settings.show()


func _on_exit_pressed():
	get_tree().quit()



func _on_fps_toggled(toggled_on:bool):
	Globals.FPS = toggled_on
	Data.save_file()


func _on_vsycn_toggled(toggled_on:bool):
	Globals.vsync = toggled_on
	Data.save_file()


func _on_antialiasing_toggled(toggled_on:bool):
	Globals.antialiasing = toggled_on
	Data.save_file()


func _on_back_pressed():
	$Menu.show()
	$Multiplayer.hide()
	$Settings.hide()


func _on_username_text_changed(new_text:String):
	Globals.username = new_text
	Data.save_file()
