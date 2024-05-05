extends CharacterBody3D
var speed = 5000
var tsunami_strength = 100
var direction = Vector3(0,0,1)

func _physics_process(delta):
	self.velocity = direction * speed * delta
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
			body.velocity = self.velocity
			body.move_and_slide()



func _on_area_3d_body_entered(body:Node3D):
	if body.is_in_group("player"):
		body.IsInWater = true
		body.damage(5)


func _on_area_3d_body_exited(body:Node3D):
	if body.is_in_group("player"):
		body.IsInWater = false
