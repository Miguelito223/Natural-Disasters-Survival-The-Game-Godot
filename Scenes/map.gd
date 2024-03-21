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

	var terrain = Terrain3D.new()
	terrain.set_collision_enabled(false)
	terrain.storage = Terrain3DStorage.new()
	terrain.texture_list = Terrain3DTextureList.new()
	add_child(terrain, true)
	terrain.material.world_background = Terrain3DMaterial.NOISE
	var texture = Terrain3DTexture.new()
	var image = load("res://Textures/leafy_grass_diff_4k.jpg")
	texture.name = "Grass"
	texture.texture_id = 0
	texture.albedo_texture = image
	terrain.texture_list.set_texture(texture.texture_id, texture)
	terrain.name = "Terrain3D"

	var noise = FastNoiseLite.new()
	noise.frequency = 0.0005
	var img = Image.create(2048, 2048, false, Image.FORMAT_RF)
	for x in 2048:
		for y in 2048:
			img.set_pixel(x,y, Color(noise.get_noise_2d(x,y) * 0.5, 0., 0., 1.))
	terrain.storage.import_images([img,null,null],  Vector3(0,0,0), 0.0, 300.)
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
	current_weather = weather.switch_weather
	switch_weather()

func switch_weather():
	var random_weather = randi_range(0,3)
	match random_weather:
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

	Globals.Temperature = lerpf(Globals.Temperature, randi_range(20,31), 0.005)
	Globals.Humidity = lerpf(Globals.Temperature, randi_range(0,20), 0.005)
	Globals.Wind_Direction = lerp(Globals.Wind_Direction, Vector3(randi_range(-1,1),0,randi_range(-1,1)), 0.005)
	Globals.Wind_speed = lerpf(Globals.Wind_speed , randi_range(0, 10), 0.005)

func is_cloud():
	for player in get_tree().get_nodes_in_group("player"):
		player.rain_node = false

	Globals.Temperature = lerpf(Globals.Temperature, randi_range(20,25), 0.005)
	Globals.Humidity = lerpf(Globals.Humidity,randi_range(10,30), 0.005)
	Globals.Wind_Direction = lerp(Globals.Wind_Direction, Vector3(randi_range(-1,1),0,randi_range(-1,1)), 0.005)
	Globals.Wind_speed = lerpf(Globals.Wind_speed, randi_range(0, 10), 0.005)

func is_raining():
	for player in get_tree().get_nodes_in_group("player"):
		player.rain_node = true

	Globals.Temperature =  lerpf(Globals.Temperature, randi_range(10,20), 0.005)
	Globals.Humidity = lerpf(Globals.Humidity, randi_range(20,40),0.005)
	Globals.Wind_Direction = lerp(Globals.Wind_Direction, Vector3(randi_range(-1,1),0,randi_range(-1,1)), 0.005)
	Globals.Wind_speed = lerpf(Globals.Wind_speed, randi_range(0, 20), 0.005)

func is_storm():
	for player in get_tree().get_nodes_in_group("player"):
		player.rain_node = true

	Globals.Temperature = lerpf(Globals.Temperature, randi_range(5,15),0.005)
	Globals.Humidity = lerpf(Globals.Humidity, randi_range(30,40), 0.005)
	Globals.Wind_Direction = lerp(Globals.Wind_Direction, Vector3(randi_range(-1,1),0,randi_range(-1,1)),0.005)
	Globals.Wind_speed = lerpf(Globals.Wind_speed, randi_range(0, 30),0.005)


func player_join(id):
	var player = player_scene.instantiate()
	player.id = id
	player.name = str(id)
	add_child(player,true)

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
