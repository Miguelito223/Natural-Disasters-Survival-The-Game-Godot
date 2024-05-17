extends Node

#Network
var ip = "127.0.0.1"
var port = 9999
var points = 0
var username = ""
var players_conected_array = []
var players_conected_list = {}
var players_conected_int = players_conected_list.size()
var Enet = ENetMultiplayerPeer.new()
var Offline = OfflineMultiplayerPeer.new()
var Websocket = WebSocketMultiplayerPeer.new()
var Enet_host: ENetConnection
var Enet_local_peer: ENetPacketPeer
var Websocket_local_peer: WebSocketPeer
var Enet_peers
var is_networking = false

#Globals Settings
var vsync = false
var FPS = false
var antialiasing = false
var volumen = 1
var volumen_music = 1
var timer_disasters = 60
var fullscreen = false
var resolution = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())

#Globals Weather
var Temperature: float = 23
var pressure: float = 10000
var oxygen: float  = 100
var bradiation: float = 0
var Humidity: float = 25
var Wind_Direction: Vector2 = Vector2(1,0)
var Wind_speed: float = 0
var is_raining: bool = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#Globals Time
var time:float = 0.0
var Day:int = 0
var Hour:int = 0
var Minute:int = 00

#Globals Weather target
var Temperature_target: float = 23
var pressure_target: float = 10000
var oxygen_target: float = 100
var bradiation_target: float = 0
var Humidity_target: float = 25
var Wind_Direction_target: Vector2 = Vector2(1,0)
var Wind_speed_target: float = 0

#Globals Weather original
var Temperature_original: float = 23
var pressure_original: float = 10000
var oxygen_original: float = 100
var bradiation_original: float = 0
var Humidity_original: float = 25
var Wind_Direction_original: Vector2 = Vector2(1,0)
var Wind_speed_original: float = 0

var seconds = Time.get_unix_time_from_system()

var main
var main_menu
var map
var local_player

var main_scene = preload("res://Scenes/main.tscn")
var map_scene = preload("res://Scenes/map_1.tscn")
var player_scene = preload("res://Scenes/player.tscn")

	
var bounding_radius_areas = {}

func convert_MetoSU(metres):
	return (metres * 39.37) / 0.75

func convert_KMPHtoMe(kmph):
	return (kmph*1000)/3600

func convert_VectorToAngle(vector):
	var x = vector.x
	var y = vector.y
	
	return atan2(y,x)

func perform_trace_collision(ply, direction):
	var space_state = ply.get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(ply.global_position, ply.global_position + direction * 60000, 1, [RigidBody3D, PhysicsBody3D])
	var result = space_state.intersect_ray(ray)

	return result

func get_node_by_id_recursive(node: Node, node_id: int) -> Node:
	if node.get_instance_id() == node_id:
		return node

	for child in node.get_children():
		var result := get_node_by_id_recursive(child, node_id)
		if result != null:
			return result

	return null

func is_below_sky(ply):
	var space_state = ply.get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(ply.global_position, ply.global_position + Vector3(0, 48000, 0), 1, [ply])
	var result = space_state.intersect_ray(ray)
	
	return !result

func calculate_exposed_area(player, range):
	var cell_size = Vector2(64, 64)  # Tamaño de la celda en unidades
	var exposed_cells = 0

	for x in range(-range, range):
		for z in range(-range, range):
			var cell_center = Vector3(x * cell_size.x + cell_size.x / 2, player.global_position.y, z * cell_size.y + cell_size.y / 2)
			var ray = PhysicsRayQueryParameters3D.create(player.global_position, cell_center, 1, [player])
			var result = player.get_world_3d().direct_space_state.intersect_ray(ray)

			if result.is_empty():
				exposed_cells += 1

	var total_cells = (range * 2) * (range * 2)  # Área total del rango cuadrado
	var area_percentage = exposed_cells / total_cells
	return clamp(area_percentage, 0, 1)


func is_outdoor(ply):
	var hit_left = perform_trace_collision(ply, Vector3(1, 0, 0))
	var hit_right = perform_trace_collision(ply, Vector3(-1, 0, 0))
	var hit_forward = perform_trace_collision(ply, Vector3(0, 0, 1))
	var hit_behind = perform_trace_collision(ply, Vector3(0, 0, -1))
	var in_tunnel = (hit_left and hit_right) and not (hit_forward and hit_behind) or ((not hit_left and not hit_right) and (hit_forward or hit_behind))
	var hit_sky = is_below_sky(ply)

	if ply.is_in_group("player"):
		if hit_sky:
			ply.Outdoor = true
		else:
			ply.Outdoor = false
		
		return hit_sky
	else:
		return hit_sky

func is_inwater(ply):
	if ply.is_in_group("player"):
		return ply.IsInWater

func is_underwater(ply):
	if ply.is_in_group("player"):
		return ply.IsUnderWater
	
func is_inlava(ply):
	if ply.is_in_group("player"):
		return ply.IsInLava

func is_underlava(ply):
	if ply.is_in_group("player"):
		return ply.IsUnderLava


func vec2_to_vec3(vector):
	return Vector3(vector.x, 0, vector.y)

func is_something_blocking_wind(entity):
	var space_state = entity.get_world_3d().direct_space_state
	var position = entity.global_position + Vector3(0, 10, 0)
	var ray = PhysicsRayQueryParameters3D.create(position, position + (vec2_to_vec3(Wind_Direction) * 300), 1, [entity])
	var result = space_state.intersect_ray(ray)

	return result

func calcule_bounding_radius(entity):
	var max_radius = 0.0
	
	for child in entity.get_children():
		if child.get_child_count() > 0:
			return calcule_bounding_radius(child)

		if child.is_class("MeshInstance3D") and child != null:
			var mesh = child.mesh
			var aabb = mesh.get_aabb()
			
			# Obtener los 8 vértices de la AABB original
			var vertices = [
				aabb.position,
				aabb.position + Vector3(aabb.size.x, 0, 0),
				aabb.position + Vector3(0, aabb.size.y, 0),
				aabb.position + Vector3(0, 0, aabb.size.z),
				aabb.position + Vector3(aabb.size.x, aabb.size.y, 0),
				aabb.position + Vector3(aabb.size.x, 0, aabb.size.z),
				aabb.position + Vector3(0, aabb.size.y, aabb.size.z),
				aabb.position + aabb.size
			]
			
			# Transformar los vértices con la matriz de transformación del MeshInstance3D
			var transformed_vertices = []
			for vertex in vertices:
				transformed_vertices.append(child.transform * vertex )
			
			# Calcular el nuevo AABB a partir de los vértices transformados
            # Calcular el radio de contorno a partir de los vértices transformados
			for vertex in transformed_vertices:
				var distance = vertex.length()
				max_radius = max(max_radius, distance)


	return max_radius



func search_in_node(node, origin: Vector3, radius: float, result: Array):
	for i in range(node.get_child_count()):
		var child = node.get_child(i)
		if child.is_class("Spatial"): # Solo considerar nodos Spatial (puedes ajustar esto según tus necesidades)
			var distance = origin.distance_to(child.global_position)
			if distance <= radius:
				result.append(child)
		# Recursión si el nodo tiene hijos
		if child.get_child_count() > 0:
			search_in_node(child, origin, radius, result)

	return result

func find_in_sphere(origin: Vector3, radius: float) -> Array:
	var result = []
	var scene_root = get_tree().get_root()
	
	result = search_in_node(scene_root, origin, radius, result)

	return result

func Area(entity):
	if not "bounding_radius_area" in entity or entity.bounding_radius_area == null:
		var bounding_radius = calcule_bounding_radius(entity)
		var bounding_radius_area = (2 * PI) * (bounding_radius * bounding_radius)
		bounding_radius_areas[entity] = bounding_radius_area
		
		return bounding_radius_area
	else:
		return entity.bounding_radius_area

func get_frame_multiplier() -> float:
	var frame_time: float = Engine.get_frames_per_second()
	if frame_time == 0:
		return 0
	else:
		return 60 / frame_time

func get_physics_multiplier() -> float:
	var physics_interval: float = get_physics_process_delta_time()
	return (200.0 / 3.0) / physics_interval

func hit_chance(chance: int) -> bool:
	if is_networking:
		if multiplayer.is_server():
			# En el servidor
			return randf() < (clamp(chance * get_physics_multiplier(), 0, 100) / 100)
		else:
			# En el cliente
			return randf() < (clamp(chance * get_frame_multiplier(), 0, 100) / 100)
	else:
		return randf() < (clamp(chance * get_physics_multiplier(), 0, 100) / 100)
	

@rpc("any_peer", "call_local")
func sync_timer(timer_int: int) -> void:
	if map == null:
		return

	print("syncring timer...")
	map.timer.stop()
	map.timer.wait_time = timer_int
	map.timer.start()

@rpc("any_peer", "call_local")
func add_player_to_list(id, player):
	players_conected_array.append(player)
	players_conected_list[id] = player
	players_conected_int = players_conected_array.size()

@rpc("any_peer", "call_local")
func remove_player_to_list(id, player):
	players_conected_array.erase(player)
	players_conected_list.erase(id)
	players_conected_int = players_conected_array.size()


@rpc("any_peer", "call_local")
func sync_points(new_value):
	points = new_value

@rpc("any_peer", "call_local")
func sync_temp(new_value):
	Temperature = new_value

@rpc("any_peer", "call_local")
func sync_humidity(new_value):
	pressure = new_value

@rpc("any_peer", "call_local")
func sync_pressure(new_value):
	pressure = new_value

@rpc("any_peer", "call_local")
func sync_oxygen(new_value):
	oxygen = new_value

@rpc("any_peer", "call_local")
func sync_bradiation(new_value):
	bradiation = new_value

@rpc("any_peer", "call_local")
func sync_wind_speed(new_value):
	Wind_speed = new_value

@rpc("any_peer", "call_local")
func sync_Wind_Direction(new_value):
	Wind_Direction = new_value

@rpc("any_peer", "call_local")
func _sync_time(time_value):
	time = time_value

@rpc("any_peer", "call_local")
func _sync_day(day_value):
	Day = day_value

@rpc("any_peer", "call_local")
func _sync_hour(hour_value):
	Hour = hour_value

@rpc("any_peer", "call_local")
func _sync_minute(minute_value):
	Minute = minute_value


func _process(_delta):
	
	if not is_networking:
		Temperature = clamp(Temperature, -275.5, 275.5)
		Humidity = clamp(Humidity, 0, 100)
		bradiation = clamp(bradiation, 0, 100)
		pressure = clamp(pressure , 0, 100000)
		oxygen = clamp(oxygen, 0, 100)
		points = clamp(points, 0, 5000)

		Temperature = lerp(Temperature, Temperature_target, 0.005)
		Humidity = lerp(Humidity, Humidity_target, 0.005)
		bradiation = lerp(bradiation, bradiation_target, 0.005)
		pressure = lerp(pressure, pressure_target, 0.005)
		oxygen = lerp(oxygen, oxygen_target, 0.005)
		Wind_Direction = lerp(Wind_Direction, Wind_Direction_target, 0.005)
		Wind_speed = lerp(Wind_speed, Wind_speed_target, 0.005)
	else:

		if multiplayer.is_server():
			Temperature = clamp(Temperature, -275.5, 275.5)
			Humidity = clamp(Humidity, 0, 100)
			bradiation = clamp(bradiation, 0, 100)
			pressure = clamp(pressure , 0, 100000)
			oxygen = clamp(oxygen, 0, 100)
			points = clamp(points, 0, 5000)

			Temperature = lerp(Temperature, Temperature_target, 0.005)
			Humidity = lerp(Humidity, Humidity_target, 0.005)
			bradiation = lerp(bradiation, bradiation_target, 0.005)
			pressure = lerp(pressure, pressure_target, 0.005)
			oxygen = lerp(oxygen, oxygen_target, 0.005)
			Wind_Direction = lerp(Wind_Direction, Wind_Direction_target, 0.005)
			Wind_speed = lerp(Wind_speed, Wind_speed_target, 0.005)
			
			sync_temp.rpc(Temperature)
			sync_humidity.rpc(Humidity)
			sync_wind_speed.rpc(Wind_speed)
			sync_Wind_Direction.rpc(Wind_Direction)
			sync_pressure.rpc(pressure)
			sync_oxygen.rpc(oxygen)
			sync_bradiation.rpc(bradiation)
			sync_points.rpc(points)
			_sync_time.rpc(time)
			_sync_day.rpc(Day)
			_sync_hour.rpc(Hour)
			_sync_minute.rpc(Minute)
		

		

func hostwithport(port_int):

	if OS.get_name() == "Web":
		var error = Websocket.create_server(port_int)
		if error == OK:
			multiplayer.multiplayer_peer = Websocket
			multiplayer.allow_object_decoding = true
			Websocket.handshake_timeout	= 60.0
			if multiplayer.is_server():
				is_networking = true
				UPNP_setup()
				main_menu.hide()
				LoadScene.load_scene(null, "map")
				multiplayer.connection_failed.connect(server_fail)
				multiplayer.server_disconnected.connect(server_disconect)
				multiplayer.connected_to_server.connect(server_connected)
		else:
			print("Fatal Error in server")
	else:
		var error = Enet.create_server(port_int)
		if error == OK:
			multiplayer.multiplayer_peer = Enet
			multiplayer.allow_object_decoding = true
			Enet_host = Enet.host
			Enet_peers = Enet_host.get_peers()
			if multiplayer.is_server():
				is_networking = true
				UPNP_setup()
				main_menu.hide()
				LoadScene.load_scene(null, "map")
				multiplayer.connection_failed.connect(server_fail)
				multiplayer.server_disconnected.connect(server_disconect)
				multiplayer.connected_to_server.connect(server_connected)

				
		else:
			print("Fatal Error in server")


func joinwithip(ip_str, port_int):

	if OS.get_name() == "Web":
		var error = Websocket.create_client("ws://" + ip_str + ":" + str(port_int))
		if error == OK:
			multiplayer.multiplayer_peer = Websocket
			multiplayer.allow_object_decoding = true
			Websocket.handshake_timeout	= 60.0
			if not multiplayer.is_server():
				is_networking = true
				main_menu.hide()
				LoadScene.load_scene(null, "res://Scenes/main.tscn")
				multiplayer.connection_failed.connect(server_fail)
				multiplayer.server_disconnected.connect(server_disconect)
				multiplayer.connected_to_server.connect(server_connected)
		else:
			print("Fatal Error in client")
	else:
		var error = Enet.create_client(ip_str, port_int)
		if error == OK:
			multiplayer.multiplayer_peer = Enet
			multiplayer.allow_object_decoding = true
			Enet_host = Enet.host
			Enet_peers = Enet_host.get_peers()
			if not multiplayer.is_server():
				is_networking = true
				main_menu.hide()
				LoadScene.load_scene(null, "res://Scenes/main.tscn")
				multiplayer.connection_failed.connect(server_fail)
				multiplayer.server_disconnected.connect(server_disconect)
				multiplayer.connected_to_server.connect(server_connected)

		else:
			print("Fatal Error in client")

func server_fail():
	print("client disconected: failed to load")
	is_networking = false
	Temperature_target = Temperature_original
	Humidity_target = Humidity_original
	pressure_target = pressure_original
	Wind_Direction_target = Wind_Direction_original
	Wind_speed_target = Wind_speed_original
	players_conected_array.clear()
	players_conected_int = players_conected_array.size()
	multiplayer.multiplayer_peer = Offline
	UnloadScene.unload_scene(map)
	main_menu.show()
	
func server_disconect():
	print("client disconected")
	is_networking = false
	Temperature_target = Temperature_original
	Humidity_target = Humidity_original
	pressure_target = pressure_original
	Wind_Direction_target = Wind_Direction_original
	Wind_speed_target = Wind_speed_original
	players_conected_array.clear()
	players_conected_int = players_conected_array.size()
	multiplayer.multiplayer_peer = Offline
	UnloadScene.unload_scene(map)
	main_menu.show()


func server_connected():
	print("connected to server :)")
	is_networking = true

func UPNP_setup():
	var upnp = UPNP.new()

	var discover_result = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:  
		print("UPNP discover Failed")
		return
	
	if upnp.get_gateway() and !upnp.get_gateway().is_valid_gateway():
		print("UPNP invalid gateway")
		return 

	var map_result_udp = upnp.add_port_mapping(port, port, "", "UDP")
	if map_result_udp != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP port UDP mapping failed")
		return

	var map_result_tcp = upnp.add_port_mapping(port, port, "", "TCP")
	if map_result_tcp != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP port TCP mapping failed")
		return

func _ready():
	Offline = OfflineMultiplayerPeer.new()

	if OS.has_feature("dedicated_server") or "s" in OS.get_cmdline_user_args() or "server" in OS.get_cmdline_user_args():
		var args = OS.get_cmdline_user_args()
		for arg in args:
			var key_value = arg.rsplit("=")
			match key_value[0]:
				"port":
					port = key_value[1].to_int()

		print("port:", port)
		print("ip:", IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1))
		
		await get_tree().create_timer(2).timeout

		hostwithport(port)

	
