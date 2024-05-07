extends CanvasLayer

var pause_state = false
var mouse_action_state = false

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

	if Globals.is_networking:
		if not is_multiplayer_authority():
			self.hide()
			return


	self.hide()
	$Menu.show()
	$Settings.hide()

	addresolutions()
	DisplayServer.window_set_size(Globals.resolution)
	get_viewport().set_size(Globals.resolution)

	$Settings/fps.button_pressed = Globals.FPS
	$Settings/vsync.button_pressed = Globals.vsync
	$Settings/Fullscreen.button_pressed = Globals.fullscreen
	$Settings/antialiasing.button_pressed = Globals.antialiasing
	$Settings/Volumen.value = Globals.volumen
	$"Settings/Volumen Music".value = Globals.volumen_music
	$Settings/Time.value = Globals.timer_disasters







func _on_ip_text_changed(new_text:String):
	Globals.ip = new_text


func _on_port_text_changed(new_text:String):
	Globals.port = int(new_text)


func _on_play_pressed():
	$Menu.hide()
	$Settings.hide()


func _on_settings_pressed():
	$Menu.hide()
	$Settings.show()


func _on_exit_pressed():
	if Globals.is_networking:
		multiplayer.multiplayer_peer.close()
	else:
		get_tree().paused = false
		Globals.Temperature_target = Globals.Temperature_original
		Globals.Humidity_target = Globals.Humidity_original
		Globals.pressure_target = Globals.pressure_original
		Globals.Wind_Direction_target = Globals.Wind_Direction_original
		Globals.Wind_speed_target = Globals.Wind_speed_original
		UnloadScene.unload_scene(Globals.map)
		Globals.main_menu.show()
		


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





func mouse_action():
	if mouse_action_state:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	mouse_action_state = !mouse_action_state

func pause():
	if !pause_state:
		hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if not Globals.is_networking:
			get_tree().paused = false
	else:
		show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if not Globals.is_networking:
			get_tree().paused = true

	pause_state = !pause_state

func _process(_delta):
	if not is_multiplayer_authority():
		return


	if Input.is_action_just_pressed("Mouse Action"):
		mouse_action()

	if Input.is_action_just_pressed("Pause"):
		pause()


func _on_time_value_changed(value):
	if not Globals.is_networking:
		Globals.timer_disasters = value
		Data.save_file()
		Globals.sync_timer(value)
		
	else:
		if not multiplayer.is_server():
			return

		if not Globals.map.started:
			return
		
		Globals.timer_disasters = value
		Data.save_file()
		Globals.sync_timer.rpc(value)
		
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

func _on_reset_player_pressed():
	get_parent()._reset_player()


func _on_return_pressed():
	if not Globals.is_networking:
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		self.hide()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		self.hide()	

func _on_volumen_music_value_changed(value):
	Globals.volumen_music = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	Data.save_file()
