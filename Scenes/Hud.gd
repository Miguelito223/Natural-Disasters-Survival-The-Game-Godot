extends CanvasLayer

@onready var player = get_parent()
var NextHeartSoundTime = Time.get_unix_time_from_system()

func _process(_delta):

	self.visible = player.is_multiplayer_authority()
	

	if not player.is_multiplayer_authority():
		return

	var freq = clamp((1-float((44-round( get_parent().body_temperature)) / 20)) * (180/60), 0.5, 20)

	if get_parent().hearth <= 0:
		freq = 0.05

	if Globals.FPS:
		$FPS.visible = true
	else:
		$FPS.visible = false

	var scale = 1 + (sin( Time.get_unix_time_from_system() * ((2*PI) * freq) ) * 0.1)

	var w = 1 * scale
	var h = 1 * scale
	var x = 272.5 - (w/2)
	var y = 972.5  - (h/2)

	$Label.text = "Temperature: " + str(snapped(Globals.Temperature, 0.1)) + "º\n" + "Humidity: " + str(round(Globals.Humidity)) + "%\n" + "Wind Direction: " + str(round(rad_to_deg(Globals.convert_VectorToAngle(Globals.Wind_Direction)))) + "º\n" + "Wind Velocity: " + str(round(Globals.Wind_speed)) + "km\n" + "Body Hearth: " + str(round(player.hearth)) + "\n" + "Body Temperature: " + str(snapped(player.body_temperature, 0.1)) + "º\n" + "Body Oxygen: " + str(round(player.body_oxygen))  + "%\n"
	$Heart.scale = Vector2(w,h)
	$Heart.position = Vector2(x,y)
	$FPS.text = "FPS: " + str(Engine.get_frames_per_second())


	if Time.get_unix_time_from_system() >= NextHeartSoundTime:
		$Heartbeat.play()
		NextHeartSoundTime = Time.get_unix_time_from_system() + freq/1

