extends Node3D

var player_scene = preload("res://Scenes/player.tscn")

enum weather_and_disaster {
	switch_weather_and_disaster,
	sun,
	cloud,
	raining,
	storm,
	linghting_storm,
	tsunami,
	meteor_shower,
	volcano,
	tornado,
	acid_rain,
	earthquake,
}

var current_weather_and_disaster = weather_and_disaster.sun

var linghting_scene = preload("res://Scenes/linghting.tscn")
var meteor_scene = preload("res://Scenes/meteors.tscn")

var noise = FastNoiseLite.new()
var noise_seed

# Called when the node enters the scene tree for the first time.
func _ready():
	if not Globals.is_networking:
		return

	get_tree().get_multiplayer().peer_connected.connect(player_join)
	get_tree().get_multiplayer().peer_disconnected.connect(player_disconect)
	get_tree().get_multiplayer().server_disconnected.connect(server_disconect)
	get_tree().get_multiplayer().connected_to_server.connect(server_connected)
	get_tree().get_multiplayer().connection_failed.connect(server_fail)

	if not OS.has_feature("dedicated_server") and get_tree().get_multiplayer().is_server():
		player_join(1)

	if get_tree().get_multiplayer().is_server():
		generate_seed()

	$Timer.wait_time = Globals.timer


func generate_seed():
	noise_seed = randi()

@rpc("call_local", "any_peer")
func receive_seeds(received_noise_seed):
	print("recibiendo semillas...")
	noise_seed = received_noise_seed
	generate_terrain()

func generate_terrain():
	print("Generating world...")

	var terrain = Terrain3D.new()
	terrain.set_collision_enabled(false)
	terrain.storage = Terrain3DStorage.new()
	terrain.texture_list = Terrain3DTextureList.new()
	add_child(terrain, true)
	terrain.material.world_background = Terrain3DMaterial.NONE
	var texture = Terrain3DTexture.new()
	var image = load("res://Textures/leafy_grass_diff_4k.jpg")
	texture.name = "Grass"
	texture.texture_id = 0
	texture.albedo_texture = image
	terrain.texture_list.set_texture(texture.texture_id, texture)
	terrain.name = "Terrain3D"

	await get_tree().create_timer(2).timeout
	
	noise.frequency = 0.0005
	noise.seed = noise_seed
	var img = Image.create(2048, 2048, false, Image.FORMAT_RF)
	for x in 2048:
		for y in 2048:
			img.set_pixel(x,y, Color(noise.get_noise_2d(x,y) * 0.5, 0., 0., 1.))
	terrain.storage.import_images([img,null,null],  Vector3(0,0,0), 0.0, 300.)

	terrain.set_collision_enabled(true)


func _process(_delta):

	match current_weather_and_disaster:
		weather_and_disaster.switch_weather_and_disaster:
			print("Sitching weather and disaster...")
		weather_and_disaster.sun:
			print("Is Sun :D")
		weather_and_disaster.cloud:
			print("is cloud")
		weather_and_disaster.raining:
			print("is raining")
		weather_and_disaster.storm:
			print("is storm")
		weather_and_disaster.linghting_storm:
			print("is linghting storm")


	for i in get_child_count():
		var object = get_child(i)
		if object.get_class() == "CharacterBody3D":
			var Wind_Velocity = Globals.convert_MetoSU(Globals.convert_KMPHtoMe(Globals.Wind_speed / 2.9225)) * Globals.Wind_Direction
			var frictional_scalar = clamp(Wind_Velocity.length(), 0, object.mass)
			var frictional_velocity = frictional_scalar * -Wind_Velocity.normalized()
			var Wind_Velocity_new = (Wind_Velocity + frictional_velocity) * -1
			object.velocity =  Wind_Velocity_new
			object.move_and_slide()
		elif object.get_class() == "RigidBody3D":
			var Wind_Velocity = Globals.convert_MetoSU(Globals.convert_KMPHtoMe(Globals.Wind_speed / 2.9225)) * Globals.Wind_Direction
			var frictional_scalar = clamp(Wind_Velocity.length(), 0, object.mass)
			var frictional_velocity = frictional_scalar * -Wind_Velocity.normalized()
			var Wind_Velocity_new = (Wind_Velocity + frictional_velocity) * -1
			object.linear_velocity =  Wind_Velocity_new

	
	
func _on_timer_timeout():
	sync_weather_and_disaster()

func sync_weather_and_disaster():
	# El servidor genera un número aleatorio y lo envía a los clientes
	var random_weather_and_disaster = randi_range(0,10)
	set_weather_and_disaster.rpc(random_weather_and_disaster)

@rpc("any_peer", "call_local")
func set_weather_and_disaster(weather_and_disaster_index):
	match weather_and_disaster_index:
		0:
			current_weather_and_disaster = weather_and_disaster.sun
			is_sun()
		1:
			current_weather_and_disaster = weather_and_disaster.cloud
			is_cloud()
		2:
			current_weather_and_disaster = weather_and_disaster.raining
			is_raining()
		3:
			current_weather_and_disaster = weather_and_disaster.storm
			is_storm()
		4:
			current_weather_and_disaster = weather_and_disaster.storm
			is_linghting_storm()

		5:
			current_weather_and_disaster = weather_and_disaster.storm
			is_tsunami()

		6:
			current_weather_and_disaster = weather_and_disaster.storm
			is_meteor_shower()
		7:
			current_weather_and_disaster = weather_and_disaster.storm
			is_volcano()
		8:
			current_weather_and_disaster = weather_and_disaster.storm
			is_tornado()
		9:
			current_weather_and_disaster = weather_and_disaster.storm
			is_acid_rain()
		10:
			current_weather_and_disaster = weather_and_disaster.storm
			is_earthquake()

func is_tsunami():
	pass

func is_linghting_storm():
	for player in get_tree().get_nodes_in_group("player"):
		player.rain_node = true

	Globals.Temperature_target =  randi_range(5,15)
	Globals.Humidity_target = randi_range(30,40)
	Globals.pressure_target = randi_range(8000,9000)
	Globals.Wind_Direction_target =  Vector3(randi_range(-1,1),0,randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(0, 30)

	for i in range(5000, 20000):
		var lighting = linghting_scene.instantiate()
		lighting.position = Vector3(randi_range(0,2048),0,randi_range(0,2048))
		add_child(lighting, true)
		await get_tree().create_timer(5).timeout


func is_meteor_shower():
	for player in get_tree().get_nodes_in_group("player"):
		player.rain_node = false

	Globals.Temperature_target = randi_range(20,31)
	Globals.Humidity_target = randi_range(0,20)
	Globals.pressure_target = randi_range(10000,10020)
	Globals.Wind_Direction_target = Vector3(randi_range(-1,1),0,randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(0, 10)

	for i in range(5000, 20000):
		var meteor = meteor_scene.instantiate()
		meteor.position = Vector3(randi_range(0,2048),1000,randi_range(0,2048))
		add_child(meteor, true)
		await get_tree().create_timer(5).timeout

func is_volcano():
	pass

func is_tornado():
	pass

func is_acid_rain():
	pass

func is_earthquake():
	pass


func is_sun():
	for player in get_tree().get_nodes_in_group("player"):
		player.rain_node = false

	Globals.Temperature_target = randi_range(20,31)
	Globals.Humidity_target = randi_range(0,20)
	Globals.pressure_target = randi_range(10000,10020)
	Globals.Wind_Direction_target = Vector3(randi_range(-1,1),0,randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(0, 10)

func is_cloud():
	for player in get_tree().get_nodes_in_group("player"):
		player.rain_node = false

	Globals.Temperature_target =  randi_range(20,25)
	Globals.Humidity_target = randi_range(10,30)
	Globals.pressure_target = randi_range(9000,10000)
	Globals.Wind_Direction_target = Vector3(randi_range(-1,1),0,randi_range(-1,1))
	Globals.Wind_speed_target =  randi_range(0, 10)

func is_raining():
	for player in get_tree().get_nodes_in_group("player"):
		player.rain_node = true

	Globals.Temperature_target =   randi_range(10,20)
	Globals.Humidity_target =  randi_range(20,40)
	Globals.pressure_target = randi_range(9000,9020)
	Globals.Wind_Direction_target =  Vector3(randi_range(-1,1),0,randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(0, 20)

func is_storm():
	for player in get_tree().get_nodes_in_group("player"):
		player.rain_node = true

	Globals.Temperature_target =  randi_range(5,15)
	Globals.Humidity_target = randi_range(30,40)
	Globals.pressure_target = randi_range(8000,9000)
	Globals.Wind_Direction_target =  Vector3(randi_range(-1,1),0,randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(0, 30)


func player_join(id):
	var player = player_scene.instantiate()
	player.id = id
	player.name = str(id)
	add_child(player,true)

	receive_seeds.rpc(noise_seed)

func player_disconect(id):
	var player = get_node(str(id))
	if is_instance_valid(player):
		player.queue_free()

func server_disconect():
	self.queue_free()
	get_parent().get_node("Main Menu").show()


func server_fail():
	get_parent().get_node("Main Menu").show()


func server_connected():
	print("connected to server :)")


func _on_player_spawner_spawned(node:Node):
	node.setspawnpos()
