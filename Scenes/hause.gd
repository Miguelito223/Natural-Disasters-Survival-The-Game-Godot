extends RigidBody3D

var bounding_radius_area = null
	
func _on_body_entered(body:Node) -> void:
	if body.is_in_group("movable_objects") and body.is_class("RigidBody3D"):
		if body.linear_velocity.x > 30 or body.linear_velocity.y > 30 or body.linear_velocity.z > 130:
			$Destruction.destroy()
		
		if self.linear_velocity.x > 10 or self.linear_velocity.y > 10 or self.linear_velocity.z > 10:
			$Destruction.destroy()
	else:
		if self.linear_velocity.x > 10 or self.linear_velocity.y > 10 or self.linear_velocity.z > 10:
			$Destruction.destroy()
