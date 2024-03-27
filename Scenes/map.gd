extends Node3D

var player_scene = preload("res://Scenes/player.tscn")

var current_weather_and_disaster = "Sun"
var current_weather_and_disaster_int = 0

var linghting_scene = preload("res://Scenes/thunder.tscn")
var meteor_scene = preload("res://Scenes/meteors.tscn")
var tornado_scene = preload("res://Scenes/tornado.tscn")
var tsunami_scene = preload("res://Scenes/tsunami.tscn")
var volcano_scene = preload("res://Scenes/Volcano.tscn")
var earthquake_scene = preload("res://Scenes/earthquake.tscn")

const HTerrain = preload("res://addons/zylann.hterrain/hterrain.gd")
const HTerrainData = preload("res://addons/zylann.hterrain/hterrain_data.gd")
const HTerrainTextureSet = preload("res://addons/zylann.hterrain/hterrain_texture_set.gd")

@export var noise: FastNoiseLite
var noise_seed
var noise_multiplier = 50.0

# You may want to change paths to your own textures
var grass_texture = load("res://Textures/texture-grass-field.jpg")


@onready var timer = $Timer

func _exit_tree():
	Globals.Temperature_target = Globals.Temperature_original
	Globals.Humidity_target = Globals.Humidity_original
	Globals.bradiation_target = Globals.bradiation_original
	Globals.oxygen_target = Globals.oxygen_original
	Globals.pressure_target = Globals.pressure_original
	Globals.Wind_Direction_target = Globals.Wind_Direction_original
	Globals.Wind_speed_target = Globals.Wind_speed_original
	$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
	$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)

# Called when the node enters the scene tree for the first time.
func _ready():
	if not Globals.is_networking:
		$Timer.wait_time = Globals.timer
		$Timer.start()
		generate_seed()
	else:

		get_tree().get_multiplayer().peer_connected.connect(player_join)
		get_tree().get_multiplayer().peer_disconnected.connect(player_disconect)
		get_tree().get_multiplayer().server_disconnected.connect(server_disconect)
		get_tree().get_multiplayer().connected_to_server.connect(server_connected)
		get_tree().get_multiplayer().connection_failed.connect(server_fail)

		if get_tree().get_multiplayer().is_server():
			generate_seed()

		if not OS.has_feature("dedicated_server") and get_tree().get_multiplayer().is_server():
			player_join(1)
		elif OS.has_feature("dedicated_server") and get_tree().get_multiplayer().is_server():
			Globals.synchronize_timer(Globals.timer)
		

		



func generate_seed():
	if not Globals.is_networking:
		noise_seed = randi()
		receive_seeds(noise_seed, 1)
	else:
		if get_tree().get_multiplayer().is_server():
			noise_seed = randi()

@rpc("call_local", "any_peer")
func receive_seeds(received_noise_seed, player_id):
	print("Recibiendo semillas del jugador ", player_id)
	noise_seed = received_noise_seed
	generate_terrain(received_noise_seed, player_id)

func generate_terrain(received_noise_seed, player_id):
	print("Generating terrain for player ", player_id )
	var terrain_data = HTerrainData.new()
	terrain_data.resize(4096)

	noise.seed = received_noise_seed

	var heightmap: Image = terrain_data.get_image(HTerrainData.CHANNEL_HEIGHT)
	var normalmap: Image = terrain_data.get_image(HTerrainData.CHANNEL_NORMAL)
	var splatmap: Image = terrain_data.get_image(HTerrainData.CHANNEL_SPLAT)

	
	for z in heightmap.get_height():
		for x in heightmap.get_width():
			# Generate height
			var h = noise_multiplier * noise.get_noise_2d(x, z)

			# Getting normal by generating extra heights directly from noise,
			# so map borders won't have seams in case you stitch them
			var h_right = noise_multiplier * noise.get_noise_2d(x + 0.1, z)
			var h_forward = noise_multiplier * noise.get_noise_2d(x, z + 0.1)
			var normal = Vector3(h - h_right, 0.1, h_forward - h).normalized()

			# Generate texture amounts
			var splat = splatmap.get_pixel(x, z)

			heightmap.set_pixel(x, z, Color(h, 0, 0))
			normalmap.set_pixel(x, z, HTerrainData.encode_normal(normal))
			splatmap.set_pixel(x, z, splat)

	# Commit modifications so they get uploaded to the graphics card
	var modified_region = Rect2(Vector2(), heightmap.get_size())
	terrain_data.notify_region_change(modified_region, HTerrainData.CHANNEL_HEIGHT)
	terrain_data.notify_region_change(modified_region, HTerrainData.CHANNEL_NORMAL)
	terrain_data.notify_region_change(modified_region, HTerrainData.CHANNEL_SPLAT)

	# Create texture set
	# NOTE: usually this is not made from script, it can be built with editor tools
	var texture_set = HTerrainTextureSet.new()
	texture_set.set_mode(HTerrainTextureSet.MODE_TEXTURES)
	texture_set.insert_slot(-1)
	texture_set.set_texture(0, HTerrainTextureSet.TYPE_ALBEDO_BUMP, grass_texture)
	# Create terrain node
	var terrain = HTerrain.new()
	terrain.set_shader_type(HTerrain.SHADER_CLASSIC4_LITE)
	terrain.set_data(terrain_data)
	terrain.set_texture_set(texture_set)
	terrain._chunk_size = 16
	terrain.lod_scale = 3
	add_child(terrain, true)

	# No need to call this, but you may need to if you edit the terrain later on
	#terrain.update_collider()

func player_join(id):
	print("Joined player id: " + str(id))
	var player = player_scene.instantiate()
	player.id = id
	player.name = str(id)
	Globals.players_conected_array.append(player)
	Globals.players_conected_list[id] = player
	Globals.players_conected_int = Globals.players_conected_array.size() - 1
	add_child(player,true)

	if get_tree().get_multiplayer().is_server():
		receive_seeds.rpc_id(id, noise_seed, id)
		Globals.synchronize_timer(Globals.timer)
	else:
		print("Not the server!!")

func player_disconect(id):
	print("Disconected player id: " + str(id))
	var player = get_node(str(id))
	if is_instance_valid(player):
		Globals.players_conected_array.erase(player)
		Globals.players_conected_list.erase(id)
		Globals.players_conected_int = Globals.players_conected_array.size() - 1
		player.queue_free()

func server_disconect():
	Globals.Temperature_target = Globals.Temperature_original
	Globals.Humidity_target = Globals.Humidity_original
	Globals.pressure_target = Globals.pressure_original
	Globals.Wind_Direction_target = Globals.Wind_Direction_original
	Globals.Wind_speed_target = Globals.Wind_speed_original
	Globals.players_conected_array.clear()
	Globals.players_conected_int = Globals.players_conected_array.size() - 1
	self.queue_free()
	get_parent().get_node("Main Menu").show()


func server_fail():
	Globals.Temperature_target = Globals.Temperature_original
	Globals.Humidity_target = Globals.Humidity_original
	Globals.pressure_target = Globals.pressure_original
	Globals.Wind_Direction_target = Globals.Wind_Direction_original
	Globals.Wind_speed_target = Globals.Wind_speed_original
	Globals.players_conected_array.clear()
	Globals.players_conected_int = Globals.players_conected_array.size() - 1
	self.queue_free()
	get_parent().get_node("Main Menu").show()


func server_connected():
	print("connected to server :)")

func wind(object):
	# Verificar si el objeto es un jugador
	if object.is_in_group("player"):
		var is_outdoor = Globals.is_outdoor(object)

		# Calcular el área expuesta al viento
		var area_percentage = Globals.calculate_exposed_area(object)
		
		# Calcular la velocidad del viento local
		var local_wind = area_percentage * Globals.Wind_speed
		if not is_outdoor:
			local_wind = 0

		object.body_wind = local_wind
		
		# Calcular la velocidad del viento y la fricción
		var wind_vel = Globals.convert_MetoSU(Globals.convert_KMPHtoMe((clamp(((clamp(local_wind / 256, 0, 1) * 5) ** 2) * local_wind, 0, local_wind) / 2.9225))) * Globals.vec2_to_vec3(Globals.Wind_Direction)
		var frictional_scalar = clamp(wind_vel.length(), -400, 400)
		var frictional_velocity = frictional_scalar * -wind_vel.normalized()
		var wind_vel_new = (wind_vel + frictional_velocity) * 0.5

		# Verificar si está al aire libre y no hay obstáculos que bloqueen el viento
		if is_outdoor and not Globals.is_something_blocking_wind(object):
			var delta_velocity = (object.get_velocity() - wind_vel_new) - object.get_velocity()
			
			if delta_velocity.length() != 0:
				object.set_velocity(delta_velocity * 0.3)
				object.move_and_slide()


	elif object.is_in_group("movable_objects") and object.is_class("RigidBody3D"):
		var is_outdoor = Globals.is_outdoor(object)

		if is_outdoor and not Globals.is_something_blocking_wind(object):
			var area = Globals.Area(object)
			var mass = object.mass

			var force_mul_area = clamp((area / 680827), 0, 1) # bigger the area >> higher the f multiplier is
			var friction_mul = clamp((mass / 50000), 0, 1) # lower the mass  >> lower frictional force 
			var avrg_mul = (force_mul_area + friction_mul) / 2 
			
			var wind_vel = Globals.convert_MetoSU(Globals.convert_KMPHtoMe(Globals.Wind_speed / 2.9225)) * Globals.vec2_to_vec3(Globals.Wind_Direction)
			var frictional_scalar = clamp(wind_vel.length(), 0, mass)
			var frictional_velocity = frictional_scalar * -wind_vel.normalized()
			var wind_vel_new = (wind_vel + frictional_velocity) * -1
			
			var windvel_cap = wind_vel_new.length() - object.get_linear_velocity().length()

			if windvel_cap > 0:
				object.add_constant_central_force(wind_vel_new * avrg_mul) 

# Llama a la función wind para cada objeto en la escena
func _physics_process(_delta):
	for object in get_tree().get_nodes_in_group("wind_effected_objects"):
		wind(object)

func _on_timer_timeout():
	sync_weather_and_disaster()


func sync_weather_and_disaster():
	if Globals.is_networking:
		if get_tree().get_multiplayer().is_server():
			var random_weather_and_disaster = randi_range(0,10)
			set_weather_and_disaster.rpc(random_weather_and_disaster)
	else:
		var random_weather_and_disaster = randi_range(0,12)
		set_weather_and_disaster(random_weather_and_disaster)		

@rpc("any_peer", "call_local")
func set_weather_and_disaster(weather_and_disaster_index):
	match weather_and_disaster_index:
		0:
			current_weather_and_disaster = "Sun"
			current_weather_and_disaster_int = 0
			is_sun()
		1:
			current_weather_and_disaster = "Cloud"
			current_weather_and_disaster_int = 1
			is_cloud()
		2:
			current_weather_and_disaster = "Raining"
			current_weather_and_disaster_int = 2
			is_raining()
		3:
			current_weather_and_disaster = "Storm"
			current_weather_and_disaster_int = 3
			is_storm()
		4:
			current_weather_and_disaster = "Linghting storm"
			current_weather_and_disaster_int = 4
			is_linghting_storm()

		5:
			current_weather_and_disaster = "Tsunami"
			current_weather_and_disaster_int = 5
			is_tsunami()

		6:
			current_weather_and_disaster = "Meteor shower"
			current_weather_and_disaster_int = 6
			is_meteor_shower()
		7:
			current_weather_and_disaster = "Volcano"
			current_weather_and_disaster_int = 7
			is_volcano()
		8:
			current_weather_and_disaster = "Tornado"
			current_weather_and_disaster_int = 8
			is_tornado()
		9:
			current_weather_and_disaster = "Acid rain"
			current_weather_and_disaster_int = 9
			is_acid_rain()
		10:
			current_weather_and_disaster = "Earthquake"
			current_weather_and_disaster_int = 10
			is_earthquake()

		11:
			current_weather_and_disaster = "Sand Storm"
			current_weather_and_disaster_int = 11
			is_sandstorm()
		12:
			current_weather_and_disaster = "blizzard"
			current_weather_and_disaster_int = 12
			is_blizzard()

func is_tsunami():
	var tsunami = tsunami_scene.instantiate()
	tsunami.position = Vector3(0,0,0)
	add_child(tsunami, true)

	Globals.Temperature_target = randi_range(20,31)
	Globals.Humidity_target = randi_range(0,20)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randi_range(10000,10020)
	Globals.Wind_Direction_target = Vector2(randi_range(-1,1),randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(0, 10)

	while current_weather_and_disaster == "Tsunami":
		var player
		
		if Globals.is_networking:
			player = Globals.players_conected_list[get_tree().get_multiplayer().get_unique_id()] 
		else:
			player = get_node("Player")

		player.rain_node.emitting = false
		player.sand_node.emitting = false
		player.dust_node.emitting = false
		player.snow_node.emitting = false
		$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 025)
		$WorldEnvironment.environment.volumetric_fog_enabled = false
		$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)	
		await get_tree().create_timer(0.5).timeout

	while current_weather_and_disaster != "Tsunami":
		if is_instance_valid(tsunami):
			tsunami.queue_free()
		await get_tree().create_timer(0.5).timeout



func is_linghting_storm():

	Globals.Temperature_target = randi_range(5,15)
	Globals.Humidity_target = randi_range(30,40)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randi_range(8000,9000)
	Globals.Wind_Direction_target =  Vector2(randi_range(-1,1),randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(0, 30)



	while current_weather_and_disaster == "Linghting storm":
		if Globals.is_networking:
			var player = Globals.players_conected_list[get_tree().get_multiplayer().get_unique_id()] 
			if Globals.is_outdoor(player):
				player.rain_node.emitting = player.is_multiplayer_authority()
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority()
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)	
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)				
		else:
			var player = get_node("Player")
			if Globals.is_outdoor(player):
				player.rain_node.emitting = true
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = true
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)

		var rand_pos = Vector3(randi_range(0,4096),1000,randi_range(0,4096))
		var space_state = get_world_3d().direct_space_state
		var ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0,10000,0))
		var result = space_state.intersect_ray(ray)				
		if randi_range(1,25) == 25:
			var lighting = linghting_scene.instantiate()
			if result.has("position"):
				lighting.position = result.position
			else:
				lighting.position = Vector3(randi_range(0,4096),0,randi_range(0,4096))

			add_child(lighting, true)

		await get_tree().create_timer(0.5).timeout





func is_meteor_shower():
	Globals.Temperature_target = randi_range(20,31)
	Globals.Humidity_target = randi_range(0,20)
	Globals.pressure_target = randi_range(10000,10020)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.Wind_Direction_target = Vector2(randi_range(-1,1),randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(0, 10)
	
	while current_weather_and_disaster == "Meteor shower":
		var player
		
		if Globals.is_networking:
			player = Globals.players_conected_list[get_tree().get_multiplayer().get_unique_id()] 
		else:
			player = get_node("Player")

		player.rain_node.emitting = false
		player.sand_node.emitting = false
		player.dust_node.emitting = false
		player.snow_node.emitting = false
		$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
		$WorldEnvironment.environment.volumetric_fog_enabled = false
		$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)	


		var meteor = meteor_scene.instantiate()
		meteor.position = Vector3(randi_range(0,4096),1000,randi_range(0,4096))
		add_child(meteor, true)

		await get_tree().create_timer(0.5).timeout

func is_blizzard():
	Globals.Temperature_target =  randi_range(-20,-35)
	Globals.Humidity_target = randi_range(20,30)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randi_range(8000,9020)
	Globals.Wind_Direction_target =  Vector2(randi_range(-1,1),randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(40, 50)

	while current_weather_and_disaster == "blizzard":
		if Globals.is_networking:
			var player = Globals.players_conected_list[get_tree().get_multiplayer().get_unique_id()] 
			if Globals.is_outdoor(player):
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = player.is_multiplayer_authority()
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority()
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)	
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)				
		else:
			var player = get_node("Player")
			if Globals.is_outdoor(player):
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = true
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = true
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1, 1, 1)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)	
				
			
		await get_tree().create_timer(0.5).timeout	


func is_sandstorm():
	Globals.Temperature_target =  randi_range(30,35)
	Globals.Humidity_target = randi_range(0,5)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randi_range(10000,10020)
	Globals.Wind_Direction_target =  Vector2(randi_range(-1,1),randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(30, 50)

	while current_weather_and_disaster == "Sand Storm":
		if Globals.is_networking:
			var player = Globals.players_conected_list[get_tree().get_multiplayer().get_unique_id()] 
			if Globals.is_outdoor(player):
				player.rain_node.emitting = false
				player.sand_node.emitting = player.is_multiplayer_authority()
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority()
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1, 0.647059, 0)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)				
		else:
			var player = get_node("Player")
			if Globals.is_outdoor(player):
				player.rain_node.emitting = false
				player.sand_node.emitting = true
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = true
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1, 0.647059, 0)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)	
			
		await get_tree().create_timer(0.5).timeout

func is_volcano():
	Globals.Temperature_target =  randi_range(30,40)
	Globals.Humidity_target = randi_range(0,10)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 0
	Globals.pressure_target = randi_range(10000,10020)
	Globals.Wind_Direction_target =  Vector2(randi_range(-1,1),randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(0, 50)

	var rand_pos = Vector3(randi_range(0,4096),1000,randi_range(0,4096))
	var space_state = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0,10000,0))
	var result = space_state.intersect_ray(ray)

	var volcano = volcano_scene.instantiate()
	if result.has("position"):
		volcano.position = result.position
	else:
		volcano.position = Vector3(randi_range(0,4096),0,randi_range(0,4096))
	
	add_child(volcano, true)

	while current_weather_and_disaster == "Volcano":
		if Globals.is_networking:
			var player = Globals.players_conected_list[get_tree().get_multiplayer().get_unique_id()] 
			if Globals.is_outdoor(player):
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = player.is_multiplayer_authority()
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority()
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(0.5,0.5,0.5)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)				
		else:
			var player = get_node("Player")
			if Globals.is_outdoor(player):
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = true
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = true
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(0.5,0.5,0.5)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)	
			
		await get_tree().create_timer(0.5).timeout

	while current_weather_and_disaster != "Volcano":
		if is_instance_valid(volcano):
			volcano.queue_free()

		await get_tree().create_timer(0.5).timeout

	


func is_tornado():

	var rand_pos = Vector3(randi_range(0,4096),1000,randi_range(0,4096))
	var space_state = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0,10000,0))
	var result = space_state.intersect_ray(ray)	

		
	var tornado = tornado_scene.instantiate()
	if result.has("position"):
		tornado.position = result.position
	else:
		tornado.position = Vector3(randi_range(0,4096),0,randi_range(0,4096))
	add_child(tornado, true)

	Globals.Temperature_target =  randi_range(5,15)
	Globals.Humidity_target = randi_range(30,40)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randi_range(8000,9000)
	Globals.Wind_Direction_target =  Vector2(randi_range(-1,1),randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(0, 30)

	while current_weather_and_disaster == "Tornado":
		if Globals.is_networking:
			var player = Globals.players_conected_list[get_tree().get_multiplayer().get_unique_id()] 
			if Globals.is_outdoor(player):
				player.rain_node.emitting =  player.is_multiplayer_authority()
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority()
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)				
		else:
			var player = get_node("Player")
			if Globals.is_outdoor(player):
				player.rain_node.emitting = true
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = true
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)	


		rand_pos = Vector3(randi_range(0,4096),1000,randi_range(0,4096))
		space_state = get_world_3d().direct_space_state
		ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0,10000,0))
		result = space_state.intersect_ray(ray)			
		
		if randi_range(1,25) == 25:
			var lighting = linghting_scene.instantiate()
			if result.has("position"):
				lighting.position = result.position
			else:
				lighting.position = Vector3(randi_range(0,4096),0,randi_range(0,4096))

			add_child(lighting, true)

		await get_tree().create_timer(0.5).timeout

	while current_weather_and_disaster != "Tornado":
		if is_instance_valid(tornado):
			tornado.queue_free()

		await get_tree().create_timer(0.5).timeout
	



func is_acid_rain():
	Globals.Temperature_target = randi_range(20,31)
	Globals.Humidity_target = randi_range(0,20)
	Globals.bradiation_target = 100
	Globals.oxygen_target = 100
	Globals.pressure_target = randi_range(10000,10020)
	Globals.Wind_Direction_target = Vector2(randi_range(-1,1),randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(0, 10)

	while current_weather_and_disaster == "Acid rain":
		if Globals.is_networking:
			var player = Globals.players_conected_list[get_tree().get_multiplayer().get_unique_id()] 
			if Globals.is_outdoor(player):
				player.rain_node.emitting = player.is_multiplayer_authority()
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority()
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(0,1,0)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(0,1,0)			
		else:
			var player = get_node("Player")
			if Globals.is_outdoor(player):
				player.rain_node.emitting = true
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = true
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(0,1,0)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(0,1,0)				

		await get_tree().create_timer(0.5).timeout
	

func is_earthquake():
	Globals.Temperature_target = randi_range(20,31)
	Globals.Humidity_target = randi_range(0,20)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randi_range(10000,10020)
	Globals.Wind_Direction_target = Vector2(randi_range(-1,1),randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(0, 10)

	var earquake = earthquake_scene.instantiate()
	add_child(earquake,true)

	while current_weather_and_disaster == "Earthquake":
		var player
		
		if Globals.is_networking:
			player = Globals.players_conected_list[get_tree().get_multiplayer().get_unique_id()] 
		else:
			player = get_node("Player")

		player.rain_node.emitting = false
		player.sand_node.emitting = false
		player.dust_node.emitting = false
		player.snow_node.emitting = false
		$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
		$WorldEnvironment.environment.volumetric_fog_enabled = false
		$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			
		await get_tree().create_timer(0.5).timeout

	while current_weather_and_disaster != "Earthquake":
		if is_instance_valid(earquake):
			earquake.queue_free()

		await get_tree().create_timer(0.5).timeout

		





func is_sun():
	Globals.Temperature_target = randi_range(20,31)
	Globals.Humidity_target = randi_range(0,20)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randi_range(10000,10020)
	Globals.Wind_Direction_target = Vector2(randi_range(-1,1),randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(0, 10)

	while current_weather_and_disaster == "Sun":
		var player
		
		if Globals.is_networking:
			player = Globals.players_conected_list[get_tree().get_multiplayer().get_unique_id()] 
		else:
			player = get_node("Player")

		player.rain_node.emitting = false
		player.sand_node.emitting = false
		player.dust_node.emitting = false
		player.snow_node.emitting = false
		$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
		$WorldEnvironment.environment.volumetric_fog_enabled = false
		$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			
		await get_tree().create_timer(0.5).timeout


func is_cloud():
	Globals.Temperature_target =  randi_range(20,25)
	Globals.Humidity_target = randi_range(10,30)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randi_range(9000,10000)
	Globals.Wind_Direction_target = Vector2(randi_range(-1,1),randi_range(-1,1))
	Globals.Wind_speed_target =  randi_range(0, 10)


	while current_weather_and_disaster == "Cloud":
		if Globals.is_networking:
			var player = Globals.players_conected_list[get_tree().get_multiplayer().get_unique_id()] 
			if Globals.is_outdoor(player):
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority()
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)				
		else:
			var player = get_node("Player")
			if Globals.is_outdoor(player):
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = true
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)				
		
		await get_tree().create_timer(0.5).timeout



func is_raining():

	Globals.Temperature_target =   randi_range(10,20)
	Globals.Humidity_target =  randi_range(20,40)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randi_range(9000,9020)
	Globals.Wind_Direction_target =  Vector2(randi_range(-1,1),randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(0, 20)
	
	while current_weather_and_disaster == "Raining":
		if Globals.is_networking:
			var player = Globals.players_conected_list[get_tree().get_multiplayer().get_unique_id()] 
			if Globals.is_outdoor(player):
				player.rain_node.emitting = player.is_multiplayer_authority()
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority()
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)				
		else:
			var player = get_node("Player")
			if Globals.is_outdoor(player):
				player.rain_node.emitting = true
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = true
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)				
		
		await get_tree().create_timer(0.5).timeout



func is_storm():
	Globals.Temperature_target =  randi_range(5,15)
	Globals.Humidity_target = randi_range(30,40)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randi_range(8000,9000)
	Globals.Wind_Direction_target =  Vector2(randi_range(-1,1),randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(30, 60)

	while current_weather_and_disaster == "Storm":
		if Globals.is_networking:
			var player = Globals.players_conected_list[get_tree().get_multiplayer().get_unique_id()] 
			if Globals.is_outdoor(player):
				player.rain_node.emitting = player.is_multiplayer_authority()
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = player.is_multiplayer_authority()
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)				
		else:
			var player = get_node("Player")
			if Globals.is_outdoor(player):
				player.rain_node.emitting = true
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 1)
				$WorldEnvironment.environment.volumetric_fog_enabled = true
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)
			else:
				player.rain_node.emitting = false
				player.sand_node.emitting = false
				player.dust_node.emitting = false
				player.snow_node.emitting = false
				$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("cloud_coverage", 0.25)
				$WorldEnvironment.environment.volumetric_fog_enabled = false
				$WorldEnvironment.environment.volumetric_fog_albedo = Color(1,1,1)				

		await get_tree().create_timer(0.5).timeout


func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		body.damage(100)


