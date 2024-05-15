extends Node3D

# Variables para configurar el lanzamiento de bolas de fuego
var fireball_scene = preload("res://Scenes/meteors.tscn")  # Escena de la bola de fuego
var earthquake_scene = preload("res://Scenes/earthquake.tscn")
@export var launch_interval = 5  # Intervalo de lanzamiento en segundos
@export var launch_force = 50000  # Fuerza de lanzamiento de la bola de fuego
@export var launch_radius = 10
@export var Lava_Level  = 125
@export var Pressure = 0
@export var IsGoingToErupt = false
@export var IsPressureLeaking = false 
var old_entities_inside_lava = {}

@onready var skeleton = $Volcano/ref_skeleton/Skeleton3D
@onready var volcano = $Volcano
@onready var volcano_area = $Volcano_Area


func _ready() -> void:
	volcano_area.get_node("CollisionShape3D").shape.radius = 360 * self.scale.x

func check_pressure():
	# Verifica si la presión del volcán es mayor o igual a 100
	if Pressure >= 100:
		# Verifica si el volcán no está en proceso de erupción
		if not IsGoingToErupt:
			# Establece que el volcán está en proceso de erupción
			IsGoingToErupt = true
			
			
			var earthquake 
			
			# Si un número aleatorio entre 1 y 3 es igual a 3
			if randi() % 3 == 0:
				# Crea una instancia del objeto que representa el terremoto
				earthquake = earthquake_scene.instantiate()
				earthquake.global_transform.origin = global_transform.origin
				get_parent().add_child(earthquake)

				
			# Llama a la función Erupt después de un tiempo aleatorio entre 10 y 20 segundos
			await get_tree().create_timer(randi_range(10, 20)).timeout
			if is_instance_valid(self):
				erupt()
				Pressure = 99
				IsGoingToErupt = false
				IsPressureLeaking = true

			await get_tree().create_timer(randi_range(10, 20)).timeout
			
			if is_instance_valid(earthquake):
				earthquake.queue_free()
				


func erupt():
	$Smoke.emitting = false
	$Erupt.emitting = true
	$"Erupt Sound".play()
	_launch_fireball(20, 1)

	await await get_tree().create_timer(10).timeout

	$Smoke.emitting = true

	Globals.Temperature_target =  randf_range(30,40)
	Globals.Humidity_target = randf_range(0,10)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 0
	Globals.pressure_target = randf_range(10000,10020)
	Globals.Wind_Direction_target =  Vector2(randf_range(-1,1),randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 50)

	while get_parent().current_weather_and_disaster == "Volcano":
		var player = Globals.local_player

		if is_instance_valid(player):
			if Globals.is_outdoor(player):
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = player.is_multiplayer_authority() or true
				player.snow_node.emitting = false
				$"../WorldEnvironment".environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$"../WorldEnvironment".environment.volumetric_fog_enabled = player.is_multiplayer_authority() or true
				$"../WorldEnvironment".environment.volumetric_fog_albedo = Color(0.5,0.5,0.5)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$"../WorldEnvironment".environment.sky.sky_material.set_shader_parameter("clouds_fuzziness", 0.25)
				$"../WorldEnvironment".environment.volumetric_fog_enabled = false
				$"../WorldEnvironment".environment.volumetric_fog_albedo = Color(1,1,1)				
			
		await get_tree().create_timer(0.5).timeout

func _process(_delta: float) -> void:
	volcano_area.global_position = get_lava_level_position()
	check_pressure()



func get_lava_level_position():
	return Vector3(self.position.x, self.position.y + Lava_Level, self.position.z)

func _launch_fireball(range: int, time: int):
	for i in range:
		var fireball = fireball_scene.instantiate()
		var launch_direction = Vector3(randi_range(-1,1), 1, randi_range(-1,1)).normalized()  # Dirección hacia arriba
		fireball.global_position = get_lava_level_position() # Posición inicial en el volcán
		fireball.scale = Vector3(1,1,1)
		fireball.is_volcano_rock = true
		fireball.apply_impulse(get_lava_level_position(), launch_direction * launch_force)  # Aplicar fuerza para lanzar la bola de fuego
		get_parent().add_child(fireball, true)  # Agregar la bola de fuego como hijo del volcán
		await get_tree().create_timer(time).timeout



func _on_volcano_area_body_entered(body:Node3D) -> void:
	if body.is_in_group("player"):
		body.IsInLava = true

		if body.camera_node:
			body.IsUnderLava = true


func _on_volcano_area_body_exited(body:Node3D) -> void:
	if body.is_in_group("player"):
		body.IsInLava = true

		if body.camera_node:
			body.IsUnderLava = true
