extends RigidBody3D



func _on_body_entered(_body:Node) -> void:
	if self.linear_velocity.x > 10 or self.linear_velocity.y > 10 or self.linear_velocity.z > 10:
		$Destruction.destroy()
