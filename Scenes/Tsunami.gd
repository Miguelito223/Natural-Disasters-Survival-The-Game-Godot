extends CharacterBody3D
var speed = 100
var move_speed = 50

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _physics_process(delta):
	self.velocity = -transform.basis.z.normalized() * speed * delta
	move_and_slide()

func _on_area_3d_body_entered(body:Node3D):
    # Ejemplo de reacción al colisionar con otro objeto
	if body.is_in_group("player"):
		body.damage(50)

	# Obtener la dirección del tsunami
	var body_direction = -body.transform.basis.z.normalized()
	# Obtener la dirección relativa del objeto al tsunami
	var relative_direction = global_transform.origin - body.global_transform.origin
	# Proyectar la dirección relativa en la dirección del tsunami
	var projected_direction = body_direction.project(relative_direction)
	# Normalizar y aplicar la velocidad de movimiento
	move_speed = projected_direction.normalized() * move_speed
