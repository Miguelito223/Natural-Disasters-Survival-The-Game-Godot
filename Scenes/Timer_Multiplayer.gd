extends Timer
var time_left_sync: float = 0.0

func _ready():
	time_left_sync = time_left

func _process(delta):
	time_left_sync -= delta
	if time_left_sync < 0:
		time_left_sync = 0

func _on_timeout():
	print("Timer Finished!")

# Función para obtener el tiempo restante sincronizado
func get_time_left_sync():
	return time_left_sync

