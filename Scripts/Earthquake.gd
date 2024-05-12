extends Node3D

@export var magnitude = 0
var magnitude_modifier = 0
var NextPhysicsTime = Time.get_ticks_msec()
var SpawnTime = Time.get_ticks_msec()
var Life = [15,20]

@onready var start_weak_earthquake = $earquake_start_sound_weak
@onready var start_strong_earthquake = $earquake_start_sound_strong
@onready var earthquake_sound = $earquake_sound
@onready var earthqueake_aftershot_sound = $earqueake_aftershot

func _physics_process(_delta):
	magnitude_modifier_increment()
	process_magnitude()

func _ready() -> void:
	PlayInitialSounds()
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
	var magnitude = floor(magnitude * magnitude_modifier)
	if randi_range(1, 8) == 1:
		var gd_shakescreen = ply.camera_node._camera_shake(amplitude)

func create_earthquake_with_parent():
	var decider = randi() % int(floor(magnitude * 2)) == 1
	if not decider:
		if int(floor(magnitude)) > 1:
			earthqueake_aftershot_sound.play()
	else:
		earthqueake_aftershot_sound.play()

func magnitude_modifier_increment():
	# Ajustar el valor de MagnitudeModifier
	self.magnitude_modifier = clamp(self.magnitude_modifier + (get_physics_process_delta_time() / 4), 0, 1)

func get_real_magnitude():
	return magnitude * magnitude_modifier

func process_magnitude():
	var magmod = magnitude_modifier
	var mag = magnitude * magmod
	
	if 0 <= mag and mag < 1:
		pass
	elif 1 <= mag and mag < 2:
		magnitude_one()
	elif 2 <= mag and mag < 3:
		magnitude_two()
	elif 3 <= mag and mag < 4:
		magnitude_three()
	elif 4 <= mag and mag < 5:
		magnitude_four()
	elif 5 <= mag and mag < 6:
		magnitude_five()
	elif 6 <= mag and mag < 7:
		magnitude_six()
	elif 7 <= mag and mag < 8:
		magnitude_seven()
	elif 8 <= mag and mag < 9:
		magnitude_eight()
	elif 9 <= mag and mag < 10:
		magnitude_nine()
	elif 10 <= mag and mag < 11:
		magnitude_ten()
	elif 11 <= mag and mag < 12:
		magnitude_eleven()
	elif 12 <= mag and mag < 13:
		magnitude_twelve()
	else:
		pass

func magnitude_one():
	var percentage = clamp(magnitude / 1.99, 0, 1)
	var bxa = randi_range(-5, 5) / 100
	var bya = randi_range(-5, 5) / 100
	var mxa = (randi_range(-4, 4) / 100) * percentage
	var mya = (randi_range(-4, 4) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_on_floor():
			send_clientside_effects(v, Vector3(xa, ya, 0), 38)

	do_physics()

func magnitude_two():
	var percentage = clamp(magnitude / 2.99, 0, 1)
	var bxa = randi_range(-10, 10) / 100
	var bya = randi_range(-10, 10) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_on_floor():
			send_clientside_effects(v, Vector3(xa, ya, 0), 38)

	do_physics()

func magnitude_three():
	var percentage = clamp(magnitude / 3.99, 0, 1)
	var bxa = randi_range(-15, 15) / 100
	var bya = randi_range(-15, 15) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya

	for v in get_tree().get_nodes_in_group("player"):
		if v.is_on_floor():
			send_clientside_effects(v, Vector3(xa, ya, 0), 38)
	
	do_physics()

func magnitude_four():
	var percentage = clamp(magnitude / 4.99, 0, 1)
	var bxa = randi_range(-20, 20) / 100
	var bya = randi_range(-20, 20) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya

	for v in get_tree().get_nodes_in_group("player"):
		if v.is_on_floor():
			send_clientside_effects(v, Vector3(xa, ya, 0), 38)
	
	do_physics()

func magnitude_five():
	var percentage = clamp(magnitude / 5.99, 0, 1)
	var bxa = randi_range(-25, 25) / 100
	var bya = randi_range(-25, 25) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya

	for v in get_tree().get_nodes_in_group("player"):
		if v.is_on_floor():
			send_clientside_effects(v, Vector3(xa, ya, 0), 38)
	
	do_physics()

func magnitude_six():
	var percentage = clamp(magnitude / 6.99, 0, 1)
	var bxa = randi_range(-30, 30) / 100
	var bya = randi_range(-30, 30) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_on_floor():
			send_clientside_effects(v, Vector3(xa, ya, 0), 38)
	
	do_physics()

func magnitude_seven():
	var percentage = clamp(magnitude / 7.99, 0, 1)
	var bxa = randi_range(-35, 35) / 100
	var bya = randi_range(-35, 35) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_on_floor():
			send_clientside_effects(v, Vector3(xa, ya, 0), 38)
	
	do_physics()

func magnitude_eight():
	var percentage = clamp(magnitude / 8.99, 0, 1)
	var bxa = randi_range(-40, 40) / 100
	var bya = randi_range(-40, 40) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_on_floor():
			send_clientside_effects(v, Vector3(xa, ya, 0), 38)
	
	do_physics()

func magnitude_nine():
	var percentage = clamp(magnitude / 9.99, 0, 1)
	var bxa = randi_range(-45, 45) / 100
	var bya = randi_range(-45, 45) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_on_floor():
			send_clientside_effects(v, Vector3(xa, ya, 0), 38)
	
	do_physics()

func magnitude_ten():
	var percentage = clamp(magnitude / 10.99, 0, 1)
	var bxa = randi_range(-50, 50) / 100
	var bya = randi_range(-50, 50) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_on_floor():
			send_clientside_effects(v, Vector3(xa, ya, 0), 38)
	
	do_physics()

func magnitude_eleven():
	var percentage = clamp(magnitude / 11.99, 0, 1)
	var bxa = randi_range(-55, 55) / 100
	var bya = randi_range(-55, 55) / 100
	var mxa = (randi_range(-5, 5) / 100) * percentage
	var mya = (randi_range(-5, 5) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_on_floor():
			send_clientside_effects(v, Vector3(xa, ya, 0), 38)
	
	do_physics()

func magnitude_twelve():
	var percentage = clamp(magnitude / 12.99, 0, 1)
	var bxa = randi_range(-1250, 1250) / 100
	var bya = randi_range(-1250, 1250) / 100
	var mxa = (randi_range(-425, 425) / 100) * percentage
	var mya = (randi_range(-425, 425) / 100) * percentage
	var xa = bxa + mxa
	var ya = bya + mya
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_on_floor():
			send_clientside_effects(v, Vector3(xa, ya, 0), 38)
	
	do_physics()

func unfreeze(v, mag):
	if randi_range(1, 1024 - (25.6 * magnitude)) == 1:
		v.freeze = false
	if randi_range(1, 512 - (25.6 * magnitude)) == 1 and v.get_class() != "worldspawn":
		v.sleeping = false
		v.freeze = false


func do_physics():
	var t = 0.10 # Obtener el valor del ConVar "gdisasters_envearthquake_simquality"
	var mag = magnitude * magnitude_modifier
	
	# Si no podemos hacer física en este momento o la magnitud es menor que 3, no hacemos nada
	if !Globals.can_do_physics(t) or mag < 3:
		return
	
	var vec = (mag * 25) * Vector3(randi_range(-15, 15) / 10, 0, randi_range(-5, 4) / 10)
	var ang_vv = Vector3((randi_range(-15, 15) / 10), 0, randi_range(-5, 4) / 10) * (mag * 8)
	
	# Si hay una posibilidad de golpear, incrementamos la velocidad angular
	if Globals.hit_chance(2):
		ang_vv *= 20
	
	# Aplicar efectos a los jugadores
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_on_floor():
			match mag:
				3.0 < 4.0:
					pass
				4.0 < 5.0:
					pass
				5.0 < 6.0:
					pass
				6.0 < 7.0:
					pass
				7.0 < 8.0:
					v.set_velocity(vec)
				8.0 < 9.0:
					v.set_velocity(vec * 1.125)
				9.0 < 10.0:
					v.set_velocity(vec * 1.5)
				10.0 < 11.0:
					v.set_velocity(vec * 2)
				11.0 < 12.0:
					v.set_velocity(vec * 2.125)
				12.0 < 13.0:
					v.set_velocity(vec * 2.5)
	
	# Aplicar efectos a las entidades
	for v in get_tree().get_nodes_in_group("movable_objects"):
		if v.get_class() == "RigidBody3D":
			var mass = v.mass
			var vel_mod = 1 - clamp(v.get_linear_velocity().length() / 2000, 0, 1)
			var ang_v = ang_vv * vel_mod
			
			match mag:
				3.0 < 4.0:
					if mass < 60 and randi_range(1, 2) == 1:
						v.add_torque_impulse(ang_v)
						v.add_central_impulse(ang_v)
				4.0 < 5.0:
					if mass < 400 and randi_range(1, 2) == 1:
						v.add_torque_impulse(ang_v)
						v.add_central_impulse(ang_v)
						unfreeze(v, mag)
				5.0 < 6.0:
					if mass < 800 and randi_range(1, 2) == 1:
						v.add_torque_impulse(ang_v)
						v.add_central_impulse(ang_v)
						unfreeze(v, mag)
				6.0 < 7.0:
					if mass < 1600 and randi_range(1, 2) == 1:
						v.add_torque_impulse(ang_v * 2)
						v.add_central_impulse(ang_v)
						unfreeze(v, mag)
				7.0 < 8.0:
					if mass < 3400 and randi_range(1, 2) == 1:
						v.add_torque_impulse(ang_v * 4)
						v.add_central_impulse(ang_v * 2)
						unfreeze(v, mag)
				8.0 < 9.0:
					if mass < 13600 and randi_range(1, 2) == 1:
						v.add_torque_impulse(ang_v * 8)
						v.add_central_impulse(ang_v * 4)
						unfreeze(v, mag)
				9.0 < 10.0:
					if mass < 37200 and randi_range(1, 2) == 1:
						v.add_torque_impulse(ang_v * 12)
						v.add_central_impulse(ang_v * 6)
						unfreeze(v, mag)
				10.0 < 11.0:
					if mass <= 50000 and randi_range(1, 2) == 1:
						v.add_torque_impulse(ang_v * 24)
						v.add_central_impulse(ang_v * 12)
						unfreeze(v, mag)
				11.0 < 12.0:
					if mass <= 80000 and randi_range(1, 2) == 1:
						v.add_torque_impulse(ang_v * 36)

