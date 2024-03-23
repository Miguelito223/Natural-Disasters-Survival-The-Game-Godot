extends GPUParticles3D

var explosion_force = 1000
var explosion_radius = 10


# Called when the node enters the scene tree for the first time.
func _ready():
	self.emitting = true
	

func _on_area_3d_body_entered(body:Node3D):
	if body.is_in_group("movable_bodys"):
		if body.is_in_group("player"):
			body.damage(50)
			
		var distance = (body.global_transform.origin - global_transform.origin).length()
		var direction = (body.global_transform.origin - global_transform.origin).normalized()
		var force = explosion_force * (1 - distance / explosion_radius)
		body.apply_impulse(global_transform.origin, direction * force)


func _on_finished():
	self.queue_free()
