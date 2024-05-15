extends WorldEnvironment

@onready var Sun = $Sun
@onready var Moon = $Moon

var minutes_per_day = 1440
var minutes_per_hour = 60
var ingame_to_real_minute_duration = (2 * PI) / minutes_per_day
var sun_node # Referencia al nodo del sol
var sun_speed = 15  # Velocidad a la que el sol se mueve en grados por hora
var sun_angle = -90 # Ángulo inicial del sol
var moon_angle = 90

@export var ingame_speed = 1
@export var initial_hour = 12:
	set(h):
		initial_hour = h
		Globals.time = ingame_to_real_minute_duration * initial_hour * minutes_per_hour

var past_minute = -1.0

func _ready():
	if Globals.is_networking:
		if multiplayer.is_server():
			Globals.time = ingame_to_real_minute_duration * initial_hour * minutes_per_hour
			Sun.rotation_degrees.x = 0
			Moon.rotation_degrees.x = 0
			Data.load_file()
	else:
		Globals.time = ingame_to_real_minute_duration * initial_hour * minutes_per_hour
		Sun.rotation_degrees.x = 0
		Moon.rotation_degrees.x = 0
		Data.load_file()		

func _process(delta):
	if Globals.is_networking:
		if multiplayer.is_server():
			Globals.time += delta * ingame_to_real_minute_duration * ingame_speed
			_recalculate_time(delta)
	else:
		Globals.time += delta * ingame_to_real_minute_duration * ingame_speed  
		_recalculate_time(delta)

func _recalculate_time(delta):
	var total_minutes = int(Globals.time / ingame_to_real_minute_duration)
	Globals.Day = int(total_minutes / minutes_per_day)

	var current_day_minutes = total_minutes % minutes_per_day
	Globals.Hour = int(current_day_minutes / minutes_per_hour)
	Globals.Minute = int(current_day_minutes % minutes_per_hour)

	if past_minute != Globals.Minute:
		past_minute = Globals.Minute

	var angle_increment = sun_speed / 60.0 * delta
	sun_angle += angle_increment
	moon_angle -= angle_increment

	Sun.rotation_degrees.x = sun_angle
	Moon.rotation_degrees.x = moon_angle