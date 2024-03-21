extends Node

const DATA_PATH = "user://SettingData.json" 
var data = {}


func save_file():
	data = {
		"Vsync": Globals.vsync,
		"Antialasing": Globals.antialiasing,
		"FPS": Globals.FPS,
		"Volumen": 0,
		"Timer": 60,
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
		Globals.timer = data.Timer
		Globals.ip = data.IP
		Globals.port = data.Port
		Globals.username = data.Username
   
	
func _ready():
	load_file()
