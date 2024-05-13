extends Camera3D

# Variables para el efecto de sacudida de pantalla
var shake_duration = 0.5
var shake_amplitude = 0.1
var shake_frequency = 30.0

# Variables internas para controlar el efecto de sacudida
var shake_timer = 0.0
var original_position = Vector3.ZERO
var shake_offset = Vector3.ZERO

func _ready():
	original_position = position

func _process(delta):
	# Si el temporizador de sacudida está activo
	if shake_timer > 0.0:
		# Calcular el desplazamiento de la sacudida
		shake_offset.x = (randf() * 2.0 - 1.0) * shake_amplitude
		shake_offset.y = (randf() * 2.0 - 1.0) * shake_amplitude
		shake_offset.z = (randf() * 2.0 - 1.0) * shake_amplitude

		# Aplicar el desplazamiento de la sacudida a la posición de la cámara
		position = original_position + shake_offset

		# Reducir el temporizador de sacudida
		shake_timer -= delta

		# Si el temporizador llega a cero, restaurar la posición original
		if shake_timer <= 0.0:
			position = original_position

func start_screen_shake(duration: float, amplitude: float, frequency: float):
	# Iniciar la sacudida de pantalla
	shake_duration = duration
	shake_amplitude = amplitude
	shake_frequency = frequency
	shake_timer = duration
