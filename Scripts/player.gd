extends CharacterBody3D

@export var id: int = 1
@export var username: String = Globals.username
@export var points: int = Globals.points

var SPEED = 0

const SPEED_RUN = 25.0
const SPEED_WALK = 15.0
const JUMP_VELOCITY = 7.0
const SENSIBILITY = 0.01
const LERP_VAL =  .15

const bob_freq = 2.0
const bob_am = 0.08
var t_bob = 0.0

@export var mass: int = 1


var Max_Hearth = 100
var Max_temp = 44
var Max_oxygen = 100
var Max_bradiation = 100

var fall_strength = 0

var min_Hearth = 0
var min_temp = 24
var min_oxygen = 0
var min_bdradiation = 0


@export var hearth: float = Max_Hearth

@export var body_temperature: float = 37
@export var body_oxygen: float = Max_oxygen
@export var body_bradiation: float = min_bdradiation
@export var body_wind: float = 0

@export var Outdoor: bool = false
@export var IsInWater: bool = false
@export var IsInLava: bool = false
@export var IsUnderWater: bool = false
@export var IsUnderLava: bool = false
@export var IsOnFire: bool = false
@export var god_mode: bool = false
@export var is_alive: bool = true

@export var swim_factor: float = 0.25
@export var swim_cap: float = 50

@onready var camera_node = $"Model/Camera3D"
@onready var rain_node = $Rain
@onready var splash_node = $splash
@onready var dust_node = $Dust
@onready var sand_node = $Sand
@onready var snow_node = $Snow
@onready var pause_menu_node = $"Pause menu"
@onready var animationplayer_node = $"Model/AnimationPlayer"
@onready var animation_tree_node = $AnimationTree
@onready var mi_personaje_node = $"Model"
@onready var label = $Name
@onready var temp_effect = $Temp_Effect/ColorRect




func _enter_tree():
	if Globals.is_networking:
		set_multiplayer_authority(str(name).to_int())

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


@rpc("any_peer", "call_local")
func damage(value):
	if not god_mode:
		setlife(hearth - value)

func ignite(time):
	IsOnFire = true
	await get_tree().create_timer(time).timeout
	IsOnFire = false

func setlife(value):
	hearth = clamp(value, min_Hearth, Max_Hearth)
	if hearth <= 0:
		is_alive = false

		Globals.points -= 1
		
		if not Globals.is_networking:
			get_tree().paused = true

		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		$"Death Menu".show()
	else:
		is_alive = true

func sneeze():
	$"Model/Camera3D/sneeze audio".play()
	$"Model/Camera3D/Sneeze".emitting = true

func vomit():	
	$"Model/Camera3D/vomit audio".play()
	$"Model/Camera3D/Vomit".emitting = true

func _ready():

	if Globals.is_networking:
		camera_node.current = is_multiplayer_authority()
		rain_node.emitting = is_multiplayer_authority()
		splash_node.emitting = is_multiplayer_authority()
		sand_node.emitting = is_multiplayer_authority()
		dust_node.emitting = is_multiplayer_authority()
		snow_node.emitting = is_multiplayer_authority()
		
		if not is_multiplayer_authority():
			return

	Globals.local_player = self
	
	rain_node.emitting = false
	sand_node.emitting = false
	splash_node.emitting = false
	dust_node.emitting = false
	snow_node.emitting = false

	print("Im the player id: " + str(id))

	_reset_player()

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func body_temp(delta):
	var body_heat_genK        = delta
	var body_heat_genMAX      = 0.01/4
	var fire_heat_emission    = 50

	var heatscale               = 0
	var coolscale               = 0

	var core_equilibrium           =  clamp((37 - body_temperature)*body_heat_genK, -body_heat_genMAX, body_heat_genMAX)
	var heatsource_equilibrium     =  clamp((fire_heat_emission * (heatscale ))*body_heat_genK, 0, body_heat_genMAX * 1.3)
	var coldsource_equilibrium     =  clamp((fire_heat_emission * ( coolscale))*body_heat_genK,body_heat_genMAX * -1.3, 0) 

	var ambient_equilibrium        = clamp(((Globals.Temperature - body_temperature)*body_heat_genK), -body_heat_genMAX*1.1, body_heat_genMAX * 1.1)
	
	if Globals.Temperature >= 5 and Globals.Temperature <= 37:
		ambient_equilibrium	= 0
	
	body_temperature = clamp(body_temperature + core_equilibrium  + heatsource_equilibrium + coldsource_equilibrium + ambient_equilibrium, min_temp, Max_temp)
	temp_effect.material.set_shader_parameter("temp", body_temperature)
	temp_effect.material.set_shader_parameter("Temp", body_temperature)

	var alpha_hot  =  1-((44-clamp(body_temperature,39,44))/5)
	var alpha_cold =  ((35-clamp(body_temperature,24,35))/11)

	if randi_range(1,25) == 25:
		if alpha_cold != 0:
			damage(alpha_hot + alpha_cold)	
		elif alpha_hot != 0:	
			damage(alpha_hot + alpha_cold)

	if body_temperature > 39 and randi() % 400 == 0:
		vomit()

	if body_temperature < 35 and randi() % 400 == 0:
		sneeze()

func body_oxy(delta):
	if Globals.oxygen <= 20 or Globals.is_inwater(self) or IsUnderWater or Globals.is_inlava(self) or IsUnderLava:
		body_oxygen = clamp(body_oxygen - 5 * delta, min_oxygen, Max_oxygen)
	else:
		body_oxygen = clamp(body_oxygen + 5 * delta, min_oxygen, Max_oxygen)
	
	
	if body_oxygen <= 0:
		if randi_range(1,25) == 25:
			damage(randi_range(1,30))

func body_rad(delta):
	if Globals.bradiation >= 80 and Globals.is_outdoor(self) and Outdoor:
		body_bradiation = clamp(body_bradiation + 5 * delta, min_bdradiation, Max_bradiation)
	else:
		body_bradiation = clamp(body_bradiation - 5 * delta, min_bdradiation, Max_bradiation)

	if body_bradiation >= 100:
		if randi_range(1,25) == 25:
			damage(randi_range(1,30))


func Underwater_or_Underlava_effects():
	$Underwater.visible = IsUnderWater
	$UnderLava.visible = IsUnderLava	

	if IsInLava:
		ignite(10)
	
	if IsInWater:
		if IsOnFire:
			IsOnFire = false	

func IsOnFire_effects():
	$Fire.emitting = IsOnFire
	if IsOnFire:
		if randi_range(1,5) == 5:
			damage(10)

func rain_sound():
	Globals.is_raining = rain_node.emitting and Globals.is_outdoor(self) and Outdoor
	if Globals.is_raining:
		if not $"Rain sound".playing:
			$"Rain sound".play()
	else:
		$"Rain sound".stop()

func wind_sound():
	if body_wind > 0 and body_wind < 50:
		if not $"Wind sound".playing:
			$"Wind sound".play()
			$"Wind Morerate sound".stop()
			$"Wind Extreme sound".stop()
	elif body_wind > 50 and body_wind < 100:
		if not $"Wind Morerate sound".playing:
			$"Wind sound".stop()
			$"Wind Morerate sound".play()
			$"Wind Extreme sound".stop()
	elif body_wind > 100:
		if not $"Wind Extreme sound".playing:
			$"Wind sound".stop()
			$"Wind Morerate sound".stop()
			$"Wind Extreme sound".play()
	else:
		$"Wind sound".stop()
		$"Wind Morerate sound".stop()
		$"Wind Extreme sound".stop()


func _process(delta):
	if Globals.is_networking:
		if not is_multiplayer_authority():
			return

			

	points = Globals.points
	username = Globals.username
	label.text = Globals.username

	body_temp(delta)
	body_oxy(delta)
	body_rad(delta)
	Underwater_or_Underlava_effects()
	IsOnFire_effects()
	rain_sound()
	wind_sound()
	

func _physics_process(delta):
	if Globals.is_networking:
		if not is_multiplayer_authority():
			return
			
	# Add the gravity.
	if not is_on_floor():
		if IsInWater or IsInLava:
			velocity.y = clampf(velocity.y - (Globals.gravity * mass * delta * swim_factor), -10000, swim_cap)
		else:
			velocity.y -= Globals.gravity * mass * delta 
			fall_strength = velocity.y
		
	else:
		if IsInWater or IsInLava:
			pass
		else:
			if fall_strength <= -90:
				damage(50)

	# Handle jump.
	if Input.is_action_just_pressed("Jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			animation_tree_node.set("parameters/is_jumping/transition_request", "true")
		
		if not is_on_floor():
			animation_tree_node.set("parameters/is_jumping/transition_request", "true")

		if IsInWater or IsInLava:
			velocity.y += JUMP_VELOCITY
			animation_tree_node.set("parameters/is_jumping/transition_request", "true")
	else:
		animation_tree_node.set("parameters/is_jumping/transition_request", "false")

	if Input.is_action_pressed("Jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			animation_tree_node.set("parameters/is_jumping/transition_request", "true")
		
		if not is_on_floor():
			animation_tree_node.set("parameters/is_jumping/transition_request", "true")

		if IsInWater:
			velocity.y += JUMP_VELOCITY
			animation_tree_node.set("parameters/is_jumping/transition_request", "true")
	else:
		animation_tree_node.set("parameters/is_jumping/transition_request", "false")

	if Input.is_action_just_pressed("Flashligh"):
		$Model/Camera3D/SpotLight3D.visible = !$Model/Camera3D/SpotLight3D.visible

	if Input.is_action_pressed("Spring"):
		SPEED = SPEED_RUN
	else:
		SPEED = SPEED_WALK

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (mi_personaje_node.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() 
	if is_on_floor():
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 7.0)
			velocity.z = lerp(velocity.z,  direction.z * SPEED, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 3.0)

	animation_tree_node.set("parameters/is_on_floor/transition_request", is_on_floor())
	
	if input_dir.x != 0 or input_dir.y != 0:
		animation_tree_node.set("parameters/movement/transition_request", "walk")
	else:
		animation_tree_node.set("parameters/movement/transition_request", "idle")
	
	move_and_slide()



func _unhandled_input(event):
	if Globals.is_networking:
		if not is_multiplayer_authority():
			return

	if event is InputEventMouseMotion:
		mi_personaje_node.rotate_y(-event.relative.x * SENSIBILITY)
		camera_node.rotate_x(-event.relative.y * SENSIBILITY)
		camera_node.rotation.x = clamp(camera_node.rotation.x, deg_to_rad(-90), deg_to_rad(90))



func _reset_player():
	if Globals.is_networking:
		if not is_multiplayer_authority():
			return

	print("Resetting player :(")

	hearth = Max_Hearth
	body_temperature = 37
	body_oxygen = Max_oxygen
	body_bradiation = min_bdradiation
	velocity = Vector3(0,0,0)
	position = $"../Spawn".position
	IsUnderWater = false
	IsUnderLava = false
	IsInWater = false
	IsInLava = false
	IsOnFire = false


	print("Finish Resetting player :D")

