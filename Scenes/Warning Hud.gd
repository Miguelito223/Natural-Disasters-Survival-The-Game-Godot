extends CanvasLayer



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Label.text = "Current Disasters/Weather is: \n" + get_parent().get_parent().current_weather_and_disaster + "\n Time Left for the next disasters: \n" + str(int(get_parent().get_parent().get_node("Timer").time_left))
