extends Node

#Network
var ip = "127.0.0.1"
var port = 25565
var is_networking = false
var username = "Michael2911"
var players_conected_array = []
var players_conected_list = {}
var players_conected_int = 0
var Enet: ENetMultiplayerPeer

#Globals Settings
var vsync = false
var FPS = false
var antialiasing = false
var volumen = 1
var timer = 60
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

@onready var main = get_tree().root.get_node("Main")
@onready var map 
var map_scene = preload("res://Scenes/map.tscn")
var player_scene = preload("res://Scenes/player.tscn")


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

func is_below_sky(ply):
	var space_state = ply.get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(ply.global_position, ply.global_position + Vector3(0, 48000, 0), 1, [ply])
	var result = space_state.intersect_ray(ray)
	
	return !result

func calculate_exposed_area(player):
	var map_size = Vector2(2048, 2048)  # Tamaño del mapa en unidades
	var cell_size = Vector2(64, 64)  # Tamaño de la celda en unidades
	var exposed_cells = 0

	for x in range(map_size.x / cell_size.x):
		for z in range(map_size.y / cell_size.y):
			var cell_center = Vector3(x * cell_size.x + cell_size.x / 2, player.global_position.y, z * cell_size.y + cell_size.y / 2)
			var ray = PhysicsRayQueryParameters3D.create(player.global_position, cell_center, 1, [player])
			var result = player.get_world_3d().direct_space_state.intersect_ray(ray)

			if result.size() == 0:
				exposed_cells += 1

	var total_cells = (map_size.x / cell_size.x) * (map_size.y / cell_size.y)
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
		if hit_sky and not in_tunnel:
			ply.Outdoor = true
		else:
			ply.Outdoor = false
		
		return hit_sky and not in_tunnel
	else:
		return hit_sky

@rpc("call_local", "any_peer")
func set_timer(timer_value: float) -> void:
	map.timer.wait_time = timer_value
	map.timer.start()

# Función para sincronizar el temporizador entre los jugadores
func synchronize_timer(timer_value: float):
	if Globals.is_networking:
		if get_tree().get_multiplayer().is_server():
			# Configurar el temporizador en el servidor
			map.timer.wait_time = timer_value
			map.timer.start()

			set_timer.rpc(timer_value)
	else:
		map.timer.wait_time = timer_value
		map.timer.start()	


func is_inwater(ply):
	if ply.is_in_group("player"):
		return ply.IsInWater
	
func is_inlava(ply):
	if ply.is_in_group("player"):
		return ply.IsInLava


func vec2_to_vec3(vector):
	return Vector3(vector.x, 0, vector.y)

func is_something_blocking_wind(entity):
	var space_state = entity.get_world_3d().direct_space_state
	var position = entity.global_position + Vector3(0, 10, 0)
	var ray = PhysicsRayQueryParameters3D.create(position, position + vec2_to_vec3(Wind_Direction) * 300, 1, [entity])
	var result = space_state.intersect_ray(ray)

	return result

func calcule_bounding_radius(entity):
	var mesh_instance = entity.get_node_or_null("MeshInstance") # Ajusta esto según la estructura de tu entidad
	if mesh_instance != null:
		var aabb = mesh_instance.get_transformed_aabb()
		var size = aabb.size
		var bounding_radius = size.length() / 2.0
		return bounding_radius
	else:
		return 0.0 # O algún otro valor predeterminado en caso de que no se encuentre MeshInstance

func Area(entity):
	if entity.bounding_radius_area == null:
		var bounding_radius = entity.calcule_bounding_radius()
		var area = (2 * PI) * (bounding_radius * bounding_radius)

		entity.bounding_radius_area = area
		return area
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
	if Globals.is_networking:
		if get_tree().get_multiplayer().is_server():
			# En el servidor
			return randf() < (clamp(chance * get_physics_multiplier(), 0, 100) / 100)
		else:
			# En el cliente
			return randf() < (clamp(chance * get_frame_multiplier(), 0, 100) / 100)
	else:
		return randf() < (clamp(chance * get_physics_multiplier(), 0, 100) / 100)
	



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

func _process(_delta):
	if not is_networking:
		Temperature = clamp(Temperature, -275.5, 275.5)
		Humidity = clamp(Humidity, 0, 100)
		bradiation = clamp(bradiation, 0, 100)
		pressure = clamp(pressure , 0, INF)
		oxygen = clamp(oxygen, 0, 100)

		Temperature = lerp(Temperature, Temperature_target, 0.005)
		Humidity = lerp(Humidity, Humidity_target, 0.005)
		bradiation = lerp(bradiation, bradiation_target, 0.005)
		pressure = lerp(pressure, pressure_target, 0.005)
		oxygen = lerp(oxygen, oxygen_target, 0.005)
		Wind_Direction = lerp(Wind_Direction, Wind_Direction_target, 0.005)
		Wind_speed = lerp(Wind_speed, Wind_speed_target, 0.005)
	else:

		if not get_tree().get_multiplayer().is_server():
			return

		Temperature = clamp(Temperature, -275.5, 275.5)
		Humidity = clamp(Humidity, 0, 100)
		bradiation = clamp(bradiation, 0, 100)
		pressure = clamp(pressure , 0, INF)
		oxygen = clamp(oxygen, 0, 100)

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
		

func hostwithport(port):
	Enet = ENetMultiplayerPeer.new()
	var error = Enet.create_server(port)
	if error == OK:
		get_tree().get_multiplayer().multiplayer_peer = Enet
		if get_tree().get_multiplayer().is_server():
			is_networking = true
			UPNP_setup()
			main.get_node("Main Menu").hide()
			map = map_scene.instantiate()
			main.add_child(map)
	else:
		print("Fatal Error in server")


func joinwithip(ip, port):
	Enet = ENetMultiplayerPeer.new()
	var error = Enet.create_client(ip, port)
	if error == OK:
		get_tree().get_multiplayer().multiplayer_peer = Enet
		if not get_tree().get_multiplayer().is_server():
			is_networking = true
			main.get_node("Main Menu").hide()
	else:
		print("Fatal Error in client")


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

	
