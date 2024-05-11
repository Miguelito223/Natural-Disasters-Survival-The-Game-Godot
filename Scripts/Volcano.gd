extends Node3D

# Variables para configurar el lanzamiento de bolas de fuego
var fireball_scene = preload("res://Scenes/meteors.tscn")  # Escena de la bola de fuego
var earthquake_scene = preload("res://Scenes/earthquake.tscn")
var launch_interval = 5  # Intervalo de lanzamiento en segundos
var launch_force = 50000  # Fuerza de lanzamiento de la bola de fuego
var launch_radius = 10
var Lava_Level  = 125
var Pressure = 0
var IsGoingToErupt = false
var IsPressureLeaking = false 
var old_entities_inside_lava = []

@onready var skeleton = $Volcano/ref_skeleton/Skeleton3D
@onready var volcano = $Volcano

func pressure_increment():
	var pressure_increase = 0.005
	var pressure_decrease = 0.01

	if not IsGoingToErupt and not IsPressureLeaking:
		Pressure = clamp(Pressure + pressure_increase, 0, 100)
		
	elif not IsGoingToErupt and IsPressureLeaking:
		Pressure = clamp(Pressure - pressure_decrease, 0, 100)
		if Pressure == 0:
			IsPressureLeaking = false

func check_pressure():
	# Verifica si la presión del volcán es mayor o igual a 100
	if Pressure >= 100:
		# Verifica si el volcán no está en proceso de erupción
		if not IsGoingToErupt:
			# Establece que el volcán está en proceso de erupción
			IsGoingToErupt = true
			
			# Crea una instancia del objeto que representa el terremoto
			var earthquake = earthquake_scene.instantiate()
			earthquake.global_transform.origin = global_transform.origin
			
			# Si un número aleatorio entre 1 y 3 es igual a 3
			if randi() % 3 == 0:
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
				

func get_entities_inside_lava() -> Array:
	var lents = {}
	var lents2 = {}

	var lpos = get_lava_level_position()

	var space_state = PhysicsServer3D.space_get_direct_state(get_world_3d().get_space())
	var query_parameters = PhysicsShapeQueryParameters3D.new()
	query_parameters.shape = SphereShape3D.new()
	query_parameters.shape.radius = 360 * scale.x
	query_parameters.transform.origin = lpos
	var result = space_state.intersect_shape(query_parameters)

	for intersection in result:
		var collider_id = intersection["collider_id"]
		var collider = Globals.get_node_by_id_recursive(get_tree().get_root(), collider_id)
		var pos = intersection["position"]

		# Comprueba si la posición Z del objeto es menor o igual a la posición Z de la lava y si es una entidad válida
		if pos.y <= lpos.y and collider.name != "WorldSpawn" and collider != self:
			lents[null] = collider
			lents2[collider] = true
			collider.is_in_lava = true
		else:
			lents2[collider] = false
			collider.is_in_lava = false

	return [lents, lents2]	

func inside_lava_effect():
	var result = get_entities_inside_lava()
	var lents = result[0]
	var lents2 = result[1]

	if old_entities_inside_lava != lents:
		for v in lents:
			if old_entities_inside_lava.has(v):
				continue

		old_entities_inside_lava = lents

	for v in lents:
		if v.is_class("CharacterBody3D"):
			if v.is_in_group("player"):
				# Aplica una reducción significativa en la velocidad
				v.velocity *= -0.9
				v.IsInLava = true

				if v.camera_node.position.y < get_lava_level_position().y:
					v.IsUnderLava = true
				else:
					v.IsUnderLava = false

		elif v.is_class("RigidBody3D"):
			# Aplica una reducción significativa en la velocidad
			v.linear_velocity *= 0.01

	old_entities_inside_lava = lents2

func lava_control():
	set_lava_level( (250/100) * Pressure)

func erupt():
	$Smoke.emitting = false
	$Erupt.emitting = true
	_launch_fireball(20)

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
		var player

		if Globals.is_networking:
			player = get_parent().get_node(str(multiplayer.get_unique_id()))
		else:
			player = get_parent().get_node("1")

		if is_instance_valid(player):
			if Globals.is_outdoor(player):
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = player.is_multiplayer_authority() or true
				player.snow_node.emitting = false
				$"../WorldEnvironment".environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$"../WorldEnvironment".environment.volumetric_fog_enabled = player.is_multiplayer_authority() or true
				$"../WorldEnvironment".environment.volumetric_fog_albedo = Color(0.5,0.5,0.5)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$"../WorldEnvironment".environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$"../WorldEnvironment".environment.volumetric_fog_enabled = false
				$"../WorldEnvironment".environment.volumetric_fog_albedo = Color(1,1,1)				
			
		await get_tree().create_timer(0.5).timeout

func _process(_delta: float) -> void:
	pressure_increment()
	check_pressure()
	inside_lava_effect()
	lava_control()

func set_lava_level(lvl: float) -> void:
	var lava_lvl = clamp(lvl, 0, 500)

	if skeleton:
		var lava_level_main_idx = skeleton.find_bone("lava_level")
		var lava_level_extension_idx = skeleton.find_bone("lava_level_extension")
		var lava_level_extension2_idx = skeleton.find_bone("lava_level_extension_02")
		
		if lava_level_main_idx >= 0 and lava_level_extension_idx >= 0 and lava_level_extension2_idx >= 0:
			
			if lava_lvl <= 100:
				skeleton.set_bone_pose_position(lava_level_main_idx, Vector3(0,lava_lvl,0))
				skeleton.set_bone_pose_position(lava_level_extension_idx, Vector3(0,0,0))
				skeleton.set_bone_pose_position(lava_level_extension2_idx, Vector3(0,0,0))
			elif lava_lvl > 100 and lava_lvl < 200:
				var diff = lava_lvl - 100
				skeleton.set_bone_pose_position(lava_level_main_idx, Vector3(0,lava_lvl,0))
				skeleton.set_bone_pose_position(lava_level_extension_idx, Vector3(0,0,diff))
				skeleton.set_bone_pose_position(lava_level_extension2_idx, Vector3(0,0,0))
			elif lava_lvl >= 200 and lava_lvl <= 300:
				var diff = lava_lvl - 200
				skeleton.set_bone_pose_position(lava_level_main_idx, Vector3(0,lava_lvl,0))
				skeleton.set_bone_pose_position(lava_level_extension_idx, Vector3(0,0,100))
				skeleton.set_bone_pose_position(lava_level_extension2_idx, Vector3(0,0,diff))
			
			print(skeleton.get_bone_pose_position(lava_level_main_idx))
			print(skeleton.get_bone_pose_position(lava_level_extension_idx))
			print(skeleton.get_bone_pose_position(lava_level_extension2_idx))
	
	
	self.Lava_Level = lava_lvl


func get_lava_level_position():
	return Vector3(volcano.position.x, volcano.position.y + Lava_Level, volcano.position.z)

func _launch_fireball(range: int):
	for i in range:
		# Instanciar una nueva bola de fuego y lanzarla
		var fireball = fireball_scene.instantiate()
		var launch_direction = Vector3(randi_range(-1,1), 1, randi_range(-1,1)).normalized()  # Dirección hacia arriba
		fireball.global_position = get_lava_level_position() # Posición inicial en el volcán
		fireball.scale = Vector3(1,1,1)
		fireball.is_volcano_rock = true
		fireball.apply_impulse(get_lava_level_position(), launch_direction * launch_force)  # Aplicar fuerza para lanzar la bola de fuego
		add_child(fireball, true)  # Agregar la bola de fuego como hijo del volcán

