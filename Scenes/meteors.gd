extends RigidBody3D

var explosion_scene = preload("res://Scenes/explosion.tscn")
var body_scale = Vector3(randi_range(1,50),randi_range(1,50),randi_range(1,50))
# Called when the node enters the scene tree for the first time.
func _ready():
	$CollisionShape3D.scale = body_scale
	$CSGSphere3D.scale = body_scale
	$Fire.scale = body_scale
	self.mass = 3 / 4 * PI * $CSGSphere3D.radius
	self.gravity_scale = Globals.gravity

func _on_body_entered(_body):
	if _body == self:
		return

	var explosion_node = explosion_scene.instantiate()
	explosion_node.position = self.position
	explosion_node.scale = body_scale
	get_parent().add_child(explosion_node, true)
	self.queue_free()

