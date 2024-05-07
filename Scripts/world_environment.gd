extends WorldEnvironment

@onready var Sun = $Sun
@onready var Moon = $Moon

var minutes_per_day = 1440
var minutes_per_hour = 60
var ingame_to_real_minute_duration = (2 * PI) / minutes_per_day

@export var ingame_speed = 1
@export var initial_hour = 12:
	set(h):
		initial_hour = h
		Globals.timer = ingame_to_real_minute_duration * initial_hour * minutes_per_hour

var past_minute = -1.0

func _ready():
	if Globals.is_networking:
		if multiplayer.is_server():
			Globals.timer = ingame_to_real_minute_duration * initial_hour * minutes_per_hour
			Data.load_file()
	else:
		Globals.timer = ingame_to_real_minute_duration * initial_hour * minutes_per_hour
		Data.load_file()		

func _process(delta):
	if Globals.is_networking:
		if multiplayer.is_server():
			Globals.timer += delta * ingame_to_real_minute_duration * ingame_speed
			_recalculate_time(delta)
	else:
		Globals.timer += delta * ingame_to_real_minute_duration * ingame_speed  
		_recalculate_time(delta)

func _recalculate_time(delta):
	var total_minutes = int(Globals.timer / ingame_to_real_minute_duration)
	Globals.Day = int(total_minutes / minutes_per_day)

	var current_day_minutes = total_minutes % minutes_per_day
	Globals.Hour = int(current_day_minutes / minutes_per_hour)
	Globals.Minute = int(current_day_minutes % minutes_per_hour)

	if past_minute != Globals.Minute:
		past_minute = Globals.Minute

	Sun.rotation_degrees.x = lerpf(Sun.rotation_degrees.x, 180 - float((Globals.Minute + Globals.Hour * 60) * 0.2500005), ingame_speed * delta)
	Moon.rotation_degrees.x = lerpf(Moon.rotation_degrees.x, 180 + float((Globals.Minute + Globals.Hour * 60) * 0.2500005), ingame_speed * delta)
	
