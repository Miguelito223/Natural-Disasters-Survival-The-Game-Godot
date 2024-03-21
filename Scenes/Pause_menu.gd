extends CanvasLayer

var pause_state = false
var tab_state = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if not is_multiplayer_authority():
		return

	$Menu.show()
	$Settings.hide()

	$Settings/fps.button_pressed = Globals.FPS
	$Settings/vsync.button_pressed = Globals.vsync
	$Settings/antialiasing.button_pressed = Globals.antialiasing
	$Settings/Volumen.value = Globals.volumen
	$Settings/Time.value = Globals.timer


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
	$Settings.hide()


func _on_settings_pressed():
	$Menu.hide()
	$Settings.show()


func _on_exit_pressed():
	
	get_tree().get_multiplayer().multiplayer_peer.close()
	Globals.is_networking = false


func _on_fps_toggled(toggled_on:bool):
	Globals.FPS = toggled_on
	Data.save_file()


func _on_vsycn_toggled(toggled_on:bool):
	Globals.vsync = toggled_on
	ProjectSettings.set_setting("display/window/vsync/vsync_mode", toggled_on)
	Data.save_file()


func _on_antialiasing_toggled(toggled_on:bool):
	Globals.antialiasing = toggled_on
	ProjectSettings.set_setting("rendering/anti_aliasing/screen_space_roughness_limiter/enabled", toggled_on)
	Data.save_file()



func _on_back_pressed():
	$Menu.show()
	$Settings.hide()





func tab():
	if tab_state:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	tab_state = !tab_state

func pause():
	if pause_state:
		hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().paused = false
	else:
		show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = true

	pause_state = !pause_state

func _input(event):
	if not is_multiplayer_authority():
		return

	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_TAB:
			tab()

		if event.pressed and event.keycode == KEY_ESCAPE:
			pause()

func _on_time_value_changed(value:float):
	Globals.timer = value

	if get_parent().get_parent().get_node("Timer") == null:
		return

	get_parent().get_parent().get_node("Timer").wait_time = value
	Data.save_file()

func _on_volumen_value_changed(value:float):
	Globals.volumen = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	Data.save_file()



