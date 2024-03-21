extends Control

var resolution = {
	"2400x1080 ": Vector2i(2400, 1080 ),
	"1920x1080": Vector2i(1920, 1080),
	"1600x900": Vector2i(1600, 900),
	"1440x1080": Vector2i(14400, 1080),
	"1440x900": Vector2i(1440, 900),
	"1366x768": Vector2i(1366, 768),
	"1360x768": Vector2i(1360, 768),
	"1280x1024": Vector2i(1280, 1024),
	"1280x962": Vector2i(1280, 962),
	"1280x960": Vector2i(1280, 960),
	"1280x800": Vector2i(1280, 800),
	"1280x768": Vector2i(1280, 768),
	"1280x720": Vector2i(1280, 720),
	"1176x664": Vector2i(1176, 664),
	"1152x648": Vector2i(1152, 648),
	"1024x768": Vector2i(1024, 768),
	"800x600": Vector2i(800, 600),
	"720x480": Vector2i(720, 480),
}

func addresolutions():
	var current_resolution = Globals.resolution
	var index = 0
	
	for r in resolution:
		$Settings/resolutions.add_item(r,index)
		
		if resolution[r] == current_resolution:
			$Settings/resolutions._select_int(index)
		index += 1


# Called when the node enters the scene tree for the first time.
func _ready():

	$Menu.show()
	$Multiplayer.hide()
	$Settings.hide()

	$Multiplayer/username.text = Globals.username
	$Multiplayer/ip.text = Globals.ip
	$Multiplayer/port.text = str(Globals.port)
	
	addresolutions()
	DisplayServer.window_set_size(Globals.resolution)
	get_viewport().set_size(Globals.resolution)

	$Settings/Fullscreen.button_pressed = Globals.fullscreen
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
	ProjectSettings.set_setting("display/window/vsync/vsync_mode", toggled_on)
	Data.save_file()


func _on_antialiasing_toggled(toggled_on:bool):
	Globals.antialiasing = toggled_on
	ProjectSettings.set_setting("rendering/anti_aliasing/screen_space_roughness_limiter/enabled", toggled_on)
	Data.save_file()


func _on_back_pressed():
	$Menu.show()
	$Multiplayer.hide()
	$Settings.hide()


func _on_username_text_changed(new_text:String):
	Globals.username = new_text
	Data.save_file()


func _on_h_slider_2_value_changed(value:float):
	Globals.timer = value
	if get_parent().get_node("Map/Timer") == null:
		return
	get_parent().get_node("Map/Timer").wait_time = value
	Data.save_file()


func _on_volumen_value_changed(value:float):
	Globals.volumen = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	Data.save_file()

func _on_resolutions_item_selected(index:int):
	var size = resolution.get($Settings/resolutions.get_item_text(index))
	DisplayServer.window_set_size(size)
	get_viewport().set_size(size)
	Globals.resolution = size
	Data.save_file()


func _on_fullscreen_toggled(toggled_on:bool):
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	Globals.fullscreen = toggled_on
	Data.save_file()
