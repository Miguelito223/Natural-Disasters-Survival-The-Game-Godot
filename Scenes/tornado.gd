extends Node3D

var movement_speed = 10
var movement_radius = 50

var ray_length = 1000
var ground_height = 0

var tornado_strength = 100
var radius = 10


@onready var ray_cast = $RayCast

func _ready():
	var ray_origin = global_position
	var ray_end = ray_origin + Vector3(0, -ray_length, 0)
	ray_cast.target_position = Vector3(0, -ray_length, 0)
	ray_cast.force_raycast_update()
	set_process(true)

func _process(delta):
	if ray_cast.is_colliding():
		ground_height = ray_cast.get_collision_point().y
		global_position.y = ground_height  # Mantener el tornado a la altura del suelo
	

	# Genera una nueva posición aleatoria dentro del radio de movimiento
	var new_position = Vector3(randi_range(-movement_radius, movement_radius),
								0,
								randi_range(-movement_radius, movement_radius))
	
	# Aplica movimiento hacia la nueva posición
	var direction = (new_position - global_position).normalized()
	translate(direction * movement_speed * delta)


func _physics_process(_delta):
	for body in $Area3D.get_overlapping_bodies():
		if body.is_in_group("movable_objects") and body.is_class("RigidBody3D"):
			var direction = (body.global_position - global_position).normalized()
			var perpendicular_direction = Vector3(-direction.z, 0, direction.x)  # Dirección perpendicular al vector hacia el tornado
			var force = perpendicular_direction * tornado_strength
			body.apply_central_impulse(force)
		elif body.is_in_group("player"):
			var direction = (body.global_position - global_position).normalized()
			var perpendicular_direction = Vector3(-direction.z, 0, direction.x)  # Dirección perpendicular al vector hacia el tornado
			var force = perpendicular_direction * tornado_strength
			body.velocity = force
			body.move_and_slide()

