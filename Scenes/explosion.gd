extends GPUParticles3D

var explosion_force = 1000
@onready var explosion_radius = $Area3D/CollisionShape3D.shape.radius


# Called when the node enters the scene tree for the first time.
func _ready():
	self.one_shot = true
	self.emitting = true
	
	

func _on_area_3d_body_entered(body:Node3D):
	if body.is_in_group("player"):
		var distance = (body.global_position - global_position).length()
		var direction = (body.global_position - global_position).normalized()
		var force = explosion_force * (1 - distance / explosion_radius)
		body.velocity = direction * force
		body.move_and_slide()

	elif body.is_in_group("movable_bodys"):
		var distance = (body.global_position - global_position).length()
		var direction = (body.global_position - global_position).normalized()
		var force = explosion_force * (1 - distance / explosion_radius)
		body.apply_central_impulse(direction * force)


func _on_finished():
	self.queue_free()
