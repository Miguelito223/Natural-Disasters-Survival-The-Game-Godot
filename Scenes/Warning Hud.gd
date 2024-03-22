extends CanvasLayer



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Label.text = "Current Disasters/Weather is: \n" + str(get_parent().get_parent().current_weather_and_disaster)
