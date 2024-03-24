extends Node

#Network
var ip = "127.0.0.1"
var port = 25565
var is_networking = false
var username = "Michael2911"
var players_conected_array = []
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
var Wind_Direction: Vector3 = Vector3(1,0,0)
var Wind_speed: float = 0
var is_raining: bool = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#Globals Weather target
var Temperature_target: float = 23
var pressure_target: float = 10000
var oxygen_target: float = 100
var bradiation_target: float = 0
var Humidity_target: float = 25
var Wind_Direction_target: Vector3 = Vector3(1,0,0)
var Wind_speed_target: float = 0

#Globals Weather original
var Temperature_original: float = 23
var pressure_original: float = 10000
var oxygen_original: float = 100
var bradiation_original: float = 0
var Humidity_original: float = 25
var Wind_Direction_original: Vector3 = Vector3(1,0,0)
var Wind_speed_original: float = 0

var seconds = Time.get_unix_time_from_system()

@onready var main = get_tree().root.get_node("Main")
@onready var map = get_tree().root.get_node("Main/Map")
var map_scene = preload("res://Scenes/map.tscn")
var player_scene = preload("res://Scenes/player.tscn")


func convert_MetoSU(metres):
	return (metres * 39.37) / 0.75

func convert_KMPHtoMe(kmph):
	return (kmph*1000)/3600

func convert_VectorToAngle(vector):
	var x = vector.x
	var y = vector.y
	var z = vector.z
	
	return atan2(z,x)

func perform_trace(ply, direction):
	var space_state = ply.get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(ply.global_transform.origin, ply.global_transform.origin + direction * 1000)
	var result = space_state.intersect_ray(ray)
	
	return !result.has("collider")

func is_below_sky(ply):
	var space_state = ply.get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(ply.global_transform.origin, ply.global_transform.origin + Vector3(0, 48000, 0))
	var result = space_state.intersect_ray(ray)

	return !result.has("collider")


func is_outdoor(ply):
	var hit_left = perform_trace(ply, Vector3(1, 0, 0))
	var hit_right = perform_trace(ply, Vector3(-1, 0, 0))
	var hit_forward = perform_trace(ply, Vector3(0, 1, 0))
	var hit_behind = perform_trace(ply, Vector3(0, -1, 0))
	var hit_below = perform_trace(ply, Vector3(0, 0, -1))
	var in_tunnel = (hit_left and hit_right) and not (hit_forward and hit_behind) or ((not hit_left and not hit_right) and (hit_forward or hit_behind))
	var hit_sky = is_below_sky(ply)

	if ply.is_in_group("player"):
		ply.Outdoor = hit_sky
	
	return hit_sky


func is_inwater(ply):
	if ply.is_in_group("player"):
		return ply.IsInWater
	
func is_inlava(ply):
	if ply.is_in_group("player"):
		return ply.IsInLava

func is_something_blocking_wind(entity):
	var space_state = entity.get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(entity.global_transform.origin + Vector3(0, 10, 0), entity.global_transform.origin + Vector3(0, 10, 0) + Wind_Direction * 300)
	var result = space_state.intersect_ray(ray)

	return !result.has("collider")

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

func _process(delta):
	if not is_networking:
		Temperature = clamp(Temperature, -275.5, 275.5)
		Humidity = clamp(Humidity, 0, 100)
		bradiation = clamp(bradiation, 0, 100)
		pressure = clamp(pressure , 0, INF)
		oxygen = clamp(oxygen, 0, 100)

		Temperature = lerp(Temperature, Temperature_target, 0.005 * delta)
		Humidity = lerp(Humidity, Humidity_target, 0.005 * delta)
		bradiation = lerp(bradiation, bradiation_target, 0.005 * delta)
		pressure = lerp(pressure, pressure_target, 0.005 * delta)
		oxygen = lerp(oxygen, oxygen_target, 0.005 * delta)
		Wind_Direction = lerp(Wind_Direction, Wind_Direction_target, 0.005 * delta)
		Wind_speed = lerp(Wind_speed, Wind_speed_target, 0.005 * delta)
	else:

		if not get_tree().get_multiplayer().is_server():
			return

		Temperature = clamp(Temperature, -275.5, 275.5)
		Humidity = clamp(Humidity, 0, 100)
		bradiation = clamp(bradiation, 0, 100)
		pressure = clamp(pressure , 0, INF)
		oxygen = clamp(oxygen, 0, 100)

		Temperature = lerp(Temperature, Temperature_target, 0.005 * delta)
		Humidity = lerp(Humidity, Humidity_target, 0.005 * delta)
		bradiation = lerp(bradiation, bradiation_target, 0.005 * delta)
		pressure = lerp(pressure, pressure_target, 0.005 * delta)
		oxygen = lerp(oxygen, oxygen_target, 0.005 * delta)
		Wind_Direction = lerp(Wind_Direction, Wind_Direction_target, 0.005 * delta)
		Wind_speed = lerp(Wind_speed, Wind_speed_target, 0.005 * delta)

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
			var map = map_scene.instantiate()
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

	
