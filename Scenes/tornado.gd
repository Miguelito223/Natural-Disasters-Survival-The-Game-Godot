extends Node3D

var movement_speed = 10
var movement_radius = 50

var ray_length = 100
var ground_height = 0

var tornado_strength = 100
var radius = 10

func _ready():
	set_process(true)

func _process(delta):
	var ray_origin = global_transform.origin
	var ray_end = ray_origin + Vector3(0, -ray_length, 0)
	var ray_cast = $RayCast
	ray_cast.cast_to = Vector3(0, -ray_length, 0)
	ray_cast.force_raycast_update()
	
	if ray_cast.is_colliding():
		ground_height = ray_cast.get_collision_point().y
		global_transform.origin.y = ground_height  # Mantener el tornado a la altura del suelo
	

	# Genera una nueva posición aleatoria dentro del radio de movimiento
	var new_position = Vector3(randi_range(-movement_radius, movement_radius),
								0,
								randi_range(-movement_radius, movement_radius))
	
	# Aplica movimiento hacia la nueva posición
	var direction = (new_position - global_transform.origin).normalized()
	translate(direction * movement_speed * delta)

			

func _on_area_3d_body_entered(body:Node3D):
	if body.is_in_group("movable_objects"):
		var direction = (body.global_transform.origin - global_transform.origin).normalized()
		var force = direction * tornado_strength
		body.apply_impulse(Vector3.ZERO, force)
