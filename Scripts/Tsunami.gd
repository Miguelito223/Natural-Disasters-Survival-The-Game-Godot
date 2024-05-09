extends CharacterBody3D

@onready var wave = $CSGBox3D
@onready var collision_wave = $CollisionShape3D
@onready var area_wave_collision = $Area3D/CollisionShape3D

var speed = 100
var tsunami_strength = 100
var tsunami_start_height = 1
var tsunami_middle_height = 1000
var tsunami_finish_height = 10
var direction = Vector3(0, 0, 1)
var distance_traveled = 0.0
var total_distance = 4097.0  # Adjust this value based on your scene


func _ready() -> void:
	wave.size.y = tsunami_start_height
	collision_wave.shape.size.y = wave.size.y
	area_wave_collision.shape.size.y = wave.size.y

func _physics_process(delta):
	var distance_this_frame = speed * delta
	distance_traveled += distance_this_frame
	var displacement = direction * distance_this_frame

	# Calculate current height based on distance traveled
	var current_height = calculate_height(distance_traveled)

	# Update wave height
	wave.size.y = current_height
	collision_wave.shape.size.y = wave.size.y
	area_wave_collision.shape.size.y = wave.size.y
	
	wave.size += displacement
	collision_wave.shape.size = wave.size
	area_wave_collision.shape.size = wave.size

	move_and_slide()

	for body in $Area3D.get_overlapping_bodies():
		if body.is_in_group("movable_objects") and body.is_class("RigidBody3D"):
			var body_direction = direction
			var relative_direction = global_transform.origin - body.global_transform.origin
			var projected_direction = body_direction.project(relative_direction)
			var force = projected_direction.normalized() * tsunami_strength
			body.apply_central_impulse(force)
			body.freeze = false
		elif body.is_in_group("player"):
			if not body.is_on_floor():
				body.velocity = self.velocity
				body.move_and_slide()

func calculate_height(distance):
	# Height increases up to a point and then decreases
	if distance <= total_distance / 2:
		return lerp(tsunami_start_height, tsunami_middle_height, distance / (total_distance / 2))
	else:
		return lerp(tsunami_middle_height, tsunami_finish_height, (distance - total_distance / 2) / (total_distance / 2))



func _on_area_3d_body_entered(body: Node3D):
	if body.is_in_group("player"):
		body.IsInWater = true

		if body.camera_node:
			body.IsUnderWater = true

func _on_area_3d_body_exited(body: Node3D):
	if body.is_in_group("player"):
		body.IsInWater = false
		
		if body.camera_node:
			body.IsUnderWater = false
