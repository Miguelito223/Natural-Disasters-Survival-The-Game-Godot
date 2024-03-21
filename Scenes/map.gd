extends Node3D

var player_scene = preload("res://Scenes/player.tscn")

enum weather {
	switch_weather,
	sun,
	cloud,
	raining,
	storm,
}

var current_weather = weather.sun

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

	match current_weather:
		weather.switch_weather:
			print("Sitching weather...")
		weather.sun:
			print("Is Sun :D")
		weather.cloud:
			print("Oh OH D: its clouding")
		weather.raining:
			print("Oh OH D: its raining")
		weather.storm:
			print("stoooooooooorm")


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
	sync_weather()

func sync_weather():
    # El servidor genera un número aleatorio y lo envía a los clientes
	var random_weather = randi_range(0, 3)
	set_weather.rpc(random_weather)

@rpc("any_peer", "call_local")
func set_weather(weather_index):
	match weather_index:
		0:
			current_weather = weather.sun
			is_sun()
		1:
			current_weather = weather.cloud
			is_cloud()
		2:
			current_weather = weather.raining
			is_raining()
		3:
			current_weather = weather.storm
			is_storm()

func is_sun():
	for player in get_tree().get_nodes_in_group("player"):
		player.rain_node = false

	Globals.Temperature_target = randi_range(20,31)
	Globals.Humidity_target = randi_range(0,20)
	Globals.Wind_Direction_target = Vector3(randi_range(-1,1),0,randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(0, 10)

func is_cloud():
	for player in get_tree().get_nodes_in_group("player"):
		player.rain_node = false

	Globals.Temperature_target =  randi_range(20,25)
	Globals.Humidity_target = randi_range(10,30)
	Globals.Wind_Direction_target = Vector3(randi_range(-1,1),0,randi_range(-1,1))
	Globals.Wind_speed_target =  randi_range(0, 10)

func is_raining():
	for player in get_tree().get_nodes_in_group("player"):
		player.rain_node = true

	Globals.Temperature_target =   randi_range(10,20)
	Globals.Humidity_target =  randi_range(20,40)
	Globals.Wind_Direction_target =  Vector3(randi_range(-1,1),0,randi_range(-1,1))
	Globals.Wind_speed_target = randi_range(0, 20)

func is_storm():
	for player in get_tree().get_nodes_in_group("player"):
		player.rain_node = true

	Globals.Temperature_target =  randi_range(5,15)
	Globals.Humidity_target = randi_range(30,40)
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
