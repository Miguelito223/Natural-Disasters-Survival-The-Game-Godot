extends Node

const DATA_PATH = "user://SettingData.json" 
var data = {}


func save_file():
	data = {
		"Vsync": Globals.vsync,
		"Antialasing": Globals.antialiasing,
		"FPS": Globals.FPS,
		"Volumen": Globals.volumen,
		"Volumen_Music": Globals.volumen_music,
		"Timer": Globals.timer_disasters,
		"Fullscreen": Globals.fullscreen,
		"Resolution": Globals.resolution,
		"IP": Globals.ip,
		"Port": Globals.port,
		"Username": Globals.username,
	}
	var datafile = FileAccess.open(DATA_PATH, FileAccess.WRITE)

	var json = JSON.stringify(data)

	datafile.store_line(json)


func load_file():
	var datafile = FileAccess.open(DATA_PATH, FileAccess.READ)
	if not datafile or not FileAccess.file_exists(DATA_PATH):
		print("Data file doesn't exist!")
		return

	if datafile.get_length() <= 0:
		print("State data file empty!")
		return

	while datafile.get_position() < datafile.get_length():
		var json_string = datafile.get_line()

		var json = JSON.new()

		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		data = json.get_data()

		Globals.FPS = data.FPS
		Globals.vsync = data.Vsync
		Globals.antialiasing = data.Antialasing
		Globals.volumen = data.Volumen
		Globals.volumen_music = data.Volumen_Music
		Globals.fullscreen = data.Fullscreen
		Globals.resolution = str_to_var("Vector2i" + data.Resolution)
		Globals.timer_disasters = data.Timer
		Globals.ip = data.IP
		Globals.port = data.Port
		Globals.username = data.Username
   
	
func _ready():
	load_file()
