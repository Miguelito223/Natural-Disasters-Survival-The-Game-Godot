extends Node3D

# Variables para configurar el lanzamiento de bolas de fuego
var fireball_scene = preload("res://Scenes/meteors.tscn")  # Escena de la bola de fuego
var launch_interval = 2  # Intervalo de lanzamiento en segundos
var launch_force = 1000  # Fuerza de lanzamiento de la bola de fuego

func _ready():
	# Llamar a la función _launch_fireball() cada 'launch_interval' segundos
	set_process(true)
	_launch_fireball()

func _launch_fireball():
	# Instanciar una nueva bola de fuego y lanzarla
	var fireball = fireball_scene.instantiate()
	var launch_direction = Vector3(0, 1, 0)  # Dirección hacia arriba
	fireball.global_position = $Volcano_Collisions/ref_skeleton/Skeleton3D.get_bone_pose_position(2)  # Posición inicial en el volcán
	fireball.apply_central_impulse(launch_direction * launch_force)  # Aplicar fuerza para lanzar la bola de fuego
	add_child(fireball, true)  # Agregar la bola de fuego como hijo del volcán

	# Llamar nuevamente a la función _launch_fireball() después de 'launch_interval' segundos
	await get_tree().create_timer(launch_interval).timeout
	_launch_fireball()
