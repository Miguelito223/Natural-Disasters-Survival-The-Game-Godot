extends CharacterBody3D

var id = 1

var SPEED = 0
const SPEED_RUN = 10.0
const SPEED_WALK = 5.0
const JUMP_VELOCITY = 7
const SENSIBILITY = 0.01

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var Max_Hearth = 100
var Max_temp = 44
var Max_oxygen = 100
var Max_bradiation = 100


var min_Hearth = 0
var min_temp = 24
var min_oxygen = 0
var min_bdradiation = 0

var mass = 75

var hearth = Max_Hearth

var body_temperature = 37
var body_oxygen = Max_oxygen
var body_bradiation = min_bdradiation

@onready var head_node =  self.get_node("Head")
@onready var camera_node =  self.get_node("Head/Camera3D")
@onready var rain_node = $Rain



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
		hearth = Max_Hearth
		body_temperature = 37
		body_oxygen = Max_oxygen
		body_bradiation = min_bdradiation
		print("you death")
		setspawnpos()
		

func _ready():
	if Globals.is_networking:
		$Head/Camera3D.current = is_multiplayer_authority()

		get_node("Pause menu").visible = is_multiplayer_authority()

		$Rain.emitting = is_multiplayer_authority()

		if not is_multiplayer_authority():
			return

		$Rain.emitting = false

		setspawnpos()

		get_node("Pause menu").visible = false

		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:

		$Head/Camera3D.current = true 

		get_node("Pause menu").visible = false

		$Rain.emitting = false

		setspawnpos()

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


		if Globals.oxygen <= 0:
			body_oxygen = clampf(body_oxygen - 5, min_oxygen, Max_oxygen)
			await get_tree().create_timer(1).timeout
		else:
			body_oxygen = clampf(body_oxygen + 5, min_oxygen, Max_oxygen)
			await get_tree().create_timer(1).timeout
		
		
		if body_oxygen <= 0:
			if randi_range(1,25) == 25:
				damage(randi_range(1,30))


		if Globals.bradiation >= 100:
			body_bradiation = clampf(body_bradiation + 1, min_bdradiation, Max_bradiation)
			await get_tree().create_timer(1).timeout
		else:
			body_bradiation = clampf(body_bradiation - 1, min_bdradiation, Max_bradiation)
			await get_tree().create_timer(1).timeout

		if body_bradiation >= 100:
			if randi_range(1,25) == 25:
				damage(randi_range(1,30))

		if Globals.Wind_speed > 0:
			if not $"Wind sound".playing:
				$"Wind sound".play()
				$"Wind Morerate sound".stop()
				$"Wind Extreme sound".stop()
		elif Globals.Wind_speed > 50:
			if not $"Wind Morerate sound".playing:
				$"Wind sound".stop()
				$"Wind Morerate sound".play()
				$"Wind Extreme sound".stop()
		elif Globals.Wind_speed > 100:
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

		if Globals.oxygen <= 0:
			body_oxygen = clampf(body_oxygen - 5, min_oxygen, Max_oxygen)
			await get_tree().create_timer(1).timeout
		else:
			body_oxygen = clampf(body_oxygen + 5, min_oxygen, Max_oxygen)
			await get_tree().create_timer(1).timeout
		
		if body_oxygen <= 0:
			if randi_range(1,25) == 25:
				damage(randi_range(1,30))


		if Globals.bradiation >= 100:
			body_bradiation = clampf(body_bradiation + 1, min_bdradiation, Max_bradiation)
			await get_tree().create_timer(1).timeout
		else:
			body_bradiation = clampf(body_bradiation - 1, min_bdradiation, Max_bradiation)
			await get_tree().create_timer(1).timeout

		if body_bradiation >= 100:
			if randi_range(1,25) == 25:
				damage(randi_range(1,30))

		if Globals.Wind_speed > 0:
			if not $"Wind sound".playing:
				$"Wind sound".play()
				$"Wind Morerate sound".stop()
				$"Wind Extreme sound".stop()
		elif Globals.Wind_speed > 50:
			if not $"Wind Morerate sound".playing:
				$"Wind sound".stop()
				$"Wind Morerate sound".play()
				$"Wind Extreme sound".stop()
		elif Globals.Wind_speed > 100:
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
			velocity.y -= gravity * mass * delta 

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

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
			velocity.y -= gravity * mass * delta 

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

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


func setspawnpos():
	self.position = Vector3(1024,1000,1024)
