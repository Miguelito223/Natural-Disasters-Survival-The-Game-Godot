extends CharacterBody3D

@export var id = 1
@export var username = Globals.username
@export var points = Globals.points

var SPEED = 0

const SPEED_RUN = 10.0
const SPEED_WALK = 5.0
const JUMP_VELOCITY = 7
const SENSIBILITY = 0.01

@export var mass = 1

# Get the gravity from the project settings to be synced with RigidBody nodes.

var Max_Hearth = 100
var Max_temp = 44
var Max_oxygen = 100
var Max_bradiation = 100


var min_Hearth = 0
var min_temp = 24
var min_oxygen = 0
var min_bdradiation = 0


@export var hearth = Max_Hearth

@export var body_temperature = 37
@export var body_oxygen = Max_oxygen
@export var body_bradiation = min_bdradiation
@export var body_wind = 0

@export var Outdoor = false
@export var IsInWater = false
@export var IsInLava = false



@onready var head_node =  self.get_node("Head")
@onready var camera_node =  self.get_node("Head/Camera3D")
@onready var rain_node = $Rain
@onready var splash_node = $splash
@onready var dust_node = $Dust
@onready var sand_node = $Sand
@onready var snow_node = $Snow
@onready var pause_menu_node = get_node("Pause menu")


func _enter_tree():
	if Globals.is_networking:
		set_multiplayer_authority(str(name).to_int())

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


@rpc("call_local", "any_peer")
func damage(value):
	setlife(hearth - value)

func setlife(value):
	hearth = clamp(value, min_Hearth, Max_Hearth)
	if hearth <= 0:
		print("you death")
		
		if not Globals.is_networking:
			get_tree().paused = true
		
		$"Death Menu".show()
		

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

		rain_node.emitting = false
		sand_node.emitting = false
		splash_node.emitting = false
		dust_node.emitting = false
		snow_node.emitting = false

		_reset_player()

		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:

		camera_node.current = true 
		rain_node.emitting = false
		splash_node.emitting = false
		sand_node.emitting = false
		dust_node.emitting = false

		_reset_player()

		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)		



func _process(delta):
	if Globals.is_networking:
		if not is_multiplayer_authority():
			return

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


		var alpha_hot  =  1-((44-clamp(body_temperature,39,44))/5)
		var alpha_cold =  ((35-clamp(body_temperature,24,35))/11)

		if randi_range(1,25) == 25:
			if alpha_cold != 0:
				damage(alpha_hot + alpha_cold)	
			elif alpha_hot != 0:	
				damage(alpha_hot + alpha_cold)
		
		if Globals.oxygen <= 20 or Globals.is_inwater(self) or IsInWater:
			body_oxygen = clamp(body_oxygen - 5 * delta, min_oxygen, Max_oxygen)
		else:
			body_oxygen = clamp(body_oxygen + 5 * delta, min_oxygen, Max_oxygen)
		
		
		if body_oxygen <= 0:
			if randi_range(1,25) == 25:
				damage(randi_range(1,30))

		

		if Globals.bradiation >= 80 and Globals.is_outdoor(self) and Outdoor:
			body_bradiation = clamp(body_bradiation + 5 * delta, min_bdradiation, Max_bradiation)
		else:
			body_bradiation = clamp(body_bradiation - 5 * delta, min_bdradiation, Max_bradiation)

		if body_bradiation >= 100:
			if randi_range(1,25) == 25:
				damage(randi_range(1,30))

		$Underwater.visible = IsInWater
		$UnderLava.visible = IsInLava	

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


	else:
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


		var alpha_hot  =  1-((44-clamp(body_temperature,39,44))/5)
		var alpha_cold =  ((35-clamp(body_temperature,24,35))/11)

		if randi_range(1,25) == 25:
			if alpha_cold != 0:
				damage(alpha_hot + alpha_cold)	
			elif alpha_hot != 0:	
				damage(alpha_hot + alpha_cold)

		

		if Globals.oxygen <= 20 or Globals.is_inwater(self) or IsInWater:
			body_oxygen = clamp(body_oxygen - 5 * delta, min_oxygen, Max_oxygen)
		else:
			body_oxygen = clamp(body_oxygen + 5 * delta, min_oxygen, Max_oxygen)
		
		
		if body_oxygen <= 0:
			if randi_range(1,25) == 25:
				damage(randi_range(1,30))

		

		if Globals.bradiation >= 80 and Globals.is_outdoor(self) and Outdoor:
			body_bradiation = clamp(body_bradiation + 5 * delta, min_bdradiation, Max_bradiation)
		else:
			body_bradiation = clamp(body_bradiation - 5 * delta, min_bdradiation, Max_bradiation)

		if body_bradiation >= 100:
			if randi_range(1,25) == 25:
				damage(randi_range(1,30))


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
		
			

	

func _physics_process(delta):
	if Globals.is_networking:
		if not is_multiplayer_authority():
			return
			
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= Globals.gravity * mass * delta 

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		if Input.is_action_just_pressed("ui_accept") and IsInWater:
			velocity.y += JUMP_VELOCITY

		if Input.is_action_pressed("Spring"):
			SPEED = SPEED_RUN
		else:
			SPEED = SPEED_WALK

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction = (head_node.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() 
		if is_on_floor():
			if direction:
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
			else:
				velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 7.0)
				velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 7.0)
		else:
			velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 3.0)
			velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 3.0)
	else:
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= Globals.gravity * mass * delta 

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		if Input.is_action_just_pressed("ui_accept") and IsInWater:
			velocity.y += JUMP_VELOCITY
		

		if Input.is_action_pressed("Spring"):
			SPEED = SPEED_RUN
		else:
			SPEED = SPEED_WALK

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction = (head_node.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() 
		if is_on_floor():
			if direction:
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
			else:
				velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 7.0)
				velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 7.0)
		else:
			velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 3.0)
			velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 3.0)
	
	move_and_slide()


func _unhandled_input(event):
	if Globals.is_networking:
		if not is_multiplayer_authority():
			return

		if event is InputEventMouseMotion:
			head_node.rotate_y(-event.relative.x * SENSIBILITY)
			camera_node.rotate_x(-event.relative.y * SENSIBILITY)
			camera_node.rotation.x = clamp(camera_node.rotation.x, deg_to_rad(-40), deg_to_rad(60))
	else:
		if event is InputEventMouseMotion:
			head_node.rotate_y(-event.relative.x * SENSIBILITY)
			camera_node.rotate_x(-event.relative.y * SENSIBILITY)
			camera_node.rotation.x = clamp(camera_node.rotation.x, deg_to_rad(-40), deg_to_rad(60))		


func _reset_player():
	hearth = Max_Hearth
	body_temperature = 37
	body_oxygen = Max_oxygen
	body_bradiation = min_bdradiation
	var rand_pos = Vector3(randi_range(0,4097),1000,randi_range(0,4097))
	var space_state = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0,10000,0))
	var result = space_state.intersect_ray(ray)
		
	if result.has("position"):
		position = result.position + Vector3(0,5,0)
	else:
		position = rand_pos

