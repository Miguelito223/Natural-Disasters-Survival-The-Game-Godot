extends Node3D

@export var magnitude = 7
var magnitude_modifier = 0
var next_physics_time = Time.get_ticks_msec()
var SpawnTime = Time.get_ticks_msec()
var Life = [15,20]


@onready var start_weak_earthquake = $earquake_start_sound_weak
@onready var start_strong_earthquake = $earquake_start_sound_strong
@onready var earthquake_sound = $earquake_sound
@onready var earthqueake_aftershot_sound = $earqueake_aftershot

func _physics_process(delta):
	magnitude_modulate_sound()
	process_magnitude()
	magnitude_modifier_increment(delta)
	

func _ready() -> void:
	PlayInitialSounds()
	
	await get_tree().create_timer(randi_range(Life[0], Life[1])).timeout
	EarthquakeDecay()

func PlayInitialSounds():
	if magnitude > 5:
		start_strong_earthquake.play()
	else:
		start_weak_earthquake.play()

func EarthquakeDecay():
	if randi_range(1, 2) == 1:
		create_earthquake_with_parent()
	queue_free()  # Esto libera el nodo actual, eliminándolo del escenario

func send_clientside_effects(ply, offset_ang, amplitude):
	if randi_range(1, 8) == 1:
		ply.camera_node._camera_shake(amplitude)

func can_do_physics(next_time):
	if Engine.get_frames_per_second() > 0:  # Asegúrate de que no estemos dividiendo por cero
		var current_time = Engine.get_frames_drawn() / Engine.get_frames_per_second()  # Obtener el tiempo actual del juego
		if current_time >= self.next_physics_time:
			if Globals.hit_chance(1):
				self.next_physics_time = current_time + (randi_range(0, 250) / 100)
			else:
				self.next_physics_time = current_time + next_time
			return true
	return false

func do_physics():
	var t = 0.1 # Obtener el valor del ConVar "gdisasters_envearthquake_simquality"
	var mag = magnitude * magnitude_modifier

	print("w2eñdèwod'0wd")
	
	# Si no podemos hacer física en este momento o la magnitud es menor que 3, no hacemos nada
	if mag < 3:
		print("Nuh uh")
		return
	
	var vec = (mag * 25) * Vector3(randi_range(-15, 15) / 10, randi_range(-5, 4) / 10, randi_range(-5, 4) / 10)
	var ang_vv = Vector3((randi_range(-15, 15) / 10), randi_range(-5, 4) / 10, randi_range(-5, 4) / 10) * (mag * 8)
	
	# Si hay una posibilidad de golpear, incrementamos la velocidad angular
	if Globals.hit_chance(2):
		ang_vv *= 20
	
	# Aplicar efectos a los jugadores
	for v in get_tree().get_nodes_in_group("player"):
		print(v)
		if v.is_on_floor():
			if 3 <= mag and mag < 4:
				pass
			elif 4 <= mag and mag < 5:
				pass
			elif 5 <= mag and mag < 6:
				pass
			elif 6 <= mag and mag < 7:
				pass
			elif 7 <= mag and mag < 8:
				v.set_velocity(vec)
			elif 8 <= mag and mag < 9:
				v.set_velocity(vec * 1.125)
			elif 9 <= mag and mag < 10:
				v.set_velocity(vec * 1.5)
			elif 10 <= mag and mag < 11:
				v.set_velocity(vec * 2)
			elif 11 <= mag and mag < 12:
				v.set_velocity(vec * 2.125)
			elif 12 <= mag and mag < 13:
				v.set_velocity(vec * 2.5)
	
	# Aplicar efectos a las entidades
	for v in get_tree().get_nodes_in_group("movable_objects"):
		print(v)
		if v.get_class() == "RigidBody3D":
			var vel_mod = 1 - clamp(v.get_linear_velocity().length() / 2000, 0, 1)
			var ang_v = ang_vv * vel_mod
			
			if 3 <= mag and mag < 4:
				if randi_range(1, 2) == 1:
					v.apply_impulse(ang_v)
			elif 4 <= mag and mag < 5:
				if randi_range(1, 2) == 1:
					v.apply_impulse(ang_v)
					unfreeze(v, mag)
			elif 5 <= mag and mag < 6:
				if randi_range(1, 2) == 1:
					v.apply_impulse(ang_v)
					unfreeze(v, mag)
			elif 6 <= mag and mag < 7:
				if randi_range(1, 2) == 1:
					v.apply_impulse(ang_v * 2)
					unfreeze(v, mag)
			elif 7 <= mag and mag < 8:
				if  randi_range(1, 2) == 1:
					v.apply_impulse(ang_v * 4)
					unfreeze(v, mag)
			elif 8 <= mag and mag < 9:
				if randi_range(1, 2) == 1:
					v.apply_impulse(ang_v * 8)
					unfreeze(v, mag)
			elif 9 <= mag and mag < 10:
				if randi_range(1, 2) == 1:
					v.apply_impulse(ang_v * 12)
					unfreeze(v, mag)
			elif 10 <= mag and mag < 11:
				if  randi_range(1, 2) == 1:
					v.apply_impulse(ang_v * 24)
					unfreeze(v, mag)
			elif 11 <= mag and mag < 12:
				if randi_range(1, 2) == 1:
					v.apply_impulse(ang_v * 36)
					unfreeze(v, mag)
			elif 12 <= mag and mag < 13:
				if randi_range(1, 2) == 1:
					v.apply_impulse(ang_v * 40)
					unfreeze(v, mag)

	
func unfreeze(v, mag):
	if randi_range(1, 1024 - (25.6 * magnitude)) == 1:
		v.freeze = false
	if randi_range(1, 512 - (25.6 * magnitude)) == 1:
		v.sleeping = false
		v.freeze = false

func magnitude_modulate_sound():
	var volume = self.magnitude  # Asumiendo que self.magnitude es una propiedad que representa la magnitud del terremoto
	var vol_mod = pow(volume / 10, 3)
	var distance_mod = 0

	# Calcula la modulación de volumen basada en la distancia al jugador (ejemplo simplificado)
	var local_player_pos = Globals.local_player.position  # Obtén la posición del jugador local
	var ray_params = PhysicsRayQueryParameters3D.create(local_player_pos, local_player_pos + Vector3(0, 0, -3000))
	var ray_result = get_world_3d().direct_space_state.intersect_ray(ray_params)
	if ray_result.size() > 0:
		distance_mod = 1 - (ray_result["position"].distance_to(local_player_pos) / 3000)

	vol_mod *= distance_mod
	
	earthquake_sound.play()
	earthquake_sound.volume_db = vol_mod


func create_earthquake_with_parent():
	var decider = randi() % int(floor(magnitude * 2)) == 1
	if not decider:
		if int(floor(magnitude)) > 1:
			earthqueake_aftershot_sound.play()
			var aftershock_magnitude = clamp(int(floor(magnitude)) - randi() % 3, 1, 10)
			var aftershock = load("res://Scenes/earthquake.tscn").instantiate()
			aftershock.magnitude = aftershock_magnitude
			aftershock.position = Vector3.ZERO
			get_parent().add_child(aftershock, true)
			aftershock.global_transform.origin = get_parent().global_transform.origin
			aftershock.show()
			
	else:
		earthqueake_aftershot_sound.play()
		var foreshock_magnitude = clamp(int(floor(magnitude)) - randi() % 3, 1, 10)
		var foreshock = load("res://Scenes/earthquake.tscn").instantiate()
		foreshock.magnitude = foreshock_magnitude
		foreshock.position = position
		get_parent().add_child(foreshock, true)
		foreshock.global_transform.origin = get_parent().global_transform.origin
		foreshock.show()

func magnitude_modifier_increment(delta):
	# Ajustar el valor de MagnitudeModifier
	self.magnitude_modifier = clamp(self.magnitude_modifier + (delta / 4), 0, 1)

func get_real_magnitude():
	return magnitude * magnitude_modifier

func process_magnitude():
	var mag = magnitude * magnitude_modifier

	print("Processing...", mag)
	
	if mag >= 0 and mag < 1:
		print("nuh uh, very low")
	elif mag >= 1 and mag < 2:
		magnitude_one()
	elif mag >= 2 and mag < 3:
		magnitude_two()
	elif mag >= 3 and mag < 4:
		magnitude_three()
	elif mag >= 4 and mag < 5:
		magnitude_four()
	elif mag >= 5 and mag < 6:
		magnitude_five()
	elif mag >= 6 and mag < 7:
		magnitude_six()
	elif mag >= 7 and mag < 8:
		magnitude_seven()
	elif mag >= 8 and mag < 9:
		magnitude_eight()
	elif mag >= 9 and mag < 10:
		magnitude_nine()
	elif mag >= 10 and mag < 11:
		magnitude_ten()
	elif mag >= 11 and mag < 12:
		magnitude_eleven()
	elif mag >= 12 and mag < 13:
		magnitude_twelve()
	else:
		print("nuh uh")

func magnitude_one():
	var percentage = clamp(magnitude / 1.99, 0, 1)
	var bxa = randi_range(-5, 5) / 100
	var bya = randi_range(-5, 5) / 100
	var mxa = (randi_range(-4, 4) / 100) * percentage
	var mya = (randi_range(-4, 4) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	do_physics()

func magnitude_two():
	var percentage = clamp(magnitude / 2.99, 0, 1)
	var bxa = randi_range(-10, 10) / 100
	var bya = randi_range(-10, 10) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	do_physics()

func magnitude_three():
	var percentage = clamp(magnitude / 3.99, 0, 1)
	var bxa = randi_range(-15, 15) / 100
	var bya = randi_range(-15, 15) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	do_physics()

func magnitude_four():
	var percentage = clamp(magnitude / 4.99, 0, 1)
	var bxa = randi_range(-20, 20) / 100
	var bya = randi_range(-20, 20) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	do_physics()

func magnitude_five():
	var percentage = clamp(magnitude / 5.99, 0, 1)
	var bxa = randi_range(-25, 25) / 100
	var bya = randi_range(-25, 25) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya	
	do_physics()

func magnitude_six():
	var percentage = clamp(magnitude / 6.99, 0, 1)
	var bxa = randi_range(-30, 30) / 100
	var bya = randi_range(-30, 30) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	do_physics()

func magnitude_seven():
	var percentage = clamp(magnitude / 7.99, 0, 1)
	var bxa = randi_range(-35, 35) / 100
	var bya = randi_range(-35, 35) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	do_physics()

func magnitude_eight():
	var percentage = clamp(magnitude / 8.99, 0, 1)
	var bxa = randi_range(-40, 40) / 100
	var bya = randi_range(-40, 40) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	do_physics()

func magnitude_nine():
	var percentage = clamp(magnitude / 9.99, 0, 1)
	var bxa = randi_range(-45, 45) / 100
	var bya = randi_range(-45, 45) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	do_physics()

func magnitude_ten():
	var percentage = clamp(magnitude / 10.99, 0, 1)
	var bxa = randi_range(-50, 50) / 100
	var bya = randi_range(-50, 50) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	do_physics()

func magnitude_eleven():
	var percentage = clamp(magnitude / 11.99, 0, 1)
	var bxa = randi_range(-55, 55) / 100
	var bya = randi_range(-55, 55) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	do_physics()

func magnitude_twelve():
	var percentage = clamp(magnitude / 12.99, 0, 1)
	var bxa = randi_range(-1250, 1250) / 100
	var bya = randi_range(-1250, 1250) / 100
	var mxa = (randi_range(-425, 425) / 100) * percentage
	var mya = (randi_range(-425, 425) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	do_physics()





