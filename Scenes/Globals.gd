extends Node

#Network
var ip = "127.0.0.1"
var port = 25565
var is_networking = false
var username = "Michael2911"
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
var Temperature = 23
var pressure = 10000
var oxygen = 100
var Humidity = 25
var Wind_Direction = Vector3(1,0,0)
var Wind_speed = 0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#Globals Weather target
var Temperature_target = 23
var pressure_target = 10000
var oxygen_target = 100
var Humidity_target = 25
var Wind_Direction_target = Vector3(1,0,0)
var Wind_speed_target = 0

#Globals Weather original
var Temperature_original = 23
var pressure_original = 10000
var oxygen_original = 100
var Humidity_original = 25
var Wind_Direction_original = Vector3(1,0,0)
var Wind_speed_original = 0

var seconds = Time.get_unix_time_from_system()

@onready var main = get_tree().root.get_node("Main")
@onready var map = get_tree().root.get_node("Main/Map")
var map_scene = preload("res://Scenes/map.tscn")


func convert_MetoSU(metres):
	return (metres * 39.37) / 0.75

func convert_KMPHtoMe(kmph):
	return (kmph*1000)/3600

func convert_VectorToAngle(vector):
	var x = vector.x
	var y = vector.y
	var z = vector.z
	
	return atan2(z,x)


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
func sync_wind_speed(new_value):
	Wind_speed = new_value

@rpc("any_peer", "call_local")
func sync_Wind_Direction(new_value):
	Wind_Direction = new_value

func _process(delta):
	if not is_networking:
		return

	if not get_tree().get_multiplayer().is_server():
		return

	Temperature = clamp(Temperature, -275.5, 275.5)
	Humidity = clamp(Humidity, 0, 100)
	pressure = clamp(pressure, 0, INF)
	oxygen = clamp(oxygen, 0, INF)

	Temperature = lerpf(Temperature, Temperature_target, 0.005)
	Humidity = lerpf(Humidity, Humidity_target, 0.005)
	pressure = clamp(pressure, pressure_target, 0.005)
	oxygen = clamp(oxygen, oxygen_target, 0.005)
	Wind_Direction = lerp(Wind_Direction, Wind_Direction_target, 0.005)
	Wind_speed = lerpf(Wind_speed, Wind_speed_target, 0.005)

	sync_temp.rpc(Temperature)
	sync_humidity.rpc(Humidity)
	sync_wind_speed.rpc(Wind_speed)
	sync_Wind_Direction.rpc(Wind_Direction)
	sync_pressure.rpc(pressure)
	sync_oxygen.rpc(oxygen)
		

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


func hostwithip(ip, port):
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

	
