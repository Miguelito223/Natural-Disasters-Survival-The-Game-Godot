extends WorldEnvironment

@onready var Sun = $Sun
@onready var Moon = $Moon

var minutes_per_day = 1440
var minutes_per_hour = 60
var ingame_to_real_minute_duration = (2 * PI) / minutes_per_day
var sun_node # Referencia al nodo del sol
var celestial_speed_per_hour = 15  # Velocidad a la que el sol se mueve en grados por hora
var sun_angle = -90 # Ángulo inicial del sol
var moon_angle = 90
var interpolation_speed = 1.0

var GlobalsData: DataResource = DataResource.load_file()


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
	else:
		Globals.time = ingame_to_real_minute_duration * initial_hour * minutes_per_hour	

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

	# Obtener la hora del día en horas decimales (ej. 14:30 = 14.5)
	var time_of_day = Globals.Hour + Globals.Minute / 60.0

	# Calcular el ángulo del sol en función de la hora del día
	sun_angle = 90 + (time_of_day * celestial_speed_per_hour)

	# Calcular el ángulo de la luna (asumiendo una fase opuesta al sol)
	moon_angle = -90 + (time_of_day * celestial_speed_per_hour)


	# Asegurarse de que los ángulos permanezcan en el rango [-90, 270]
	if sun_angle < -90:
		sun_angle += 360
	if moon_angle < -90:
		moon_angle += 360

	Sun.rotation_degrees.x = lerp(Sun.rotation_degrees.x,sun_angle, interpolation_speed * delta)
	Moon.rotation_degrees.x = lerp(Moon.rotation_degrees.x,moon_angle, interpolation_speed * delta)