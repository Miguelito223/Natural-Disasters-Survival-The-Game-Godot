extends Area3D


func _on_body_entered(body:Node3D):
	if body.is_in_group("Player"):
		body.damage(50)
