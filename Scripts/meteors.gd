extends RigidBody3D

var explosion_scene = preload("res://Scenes/explosion.tscn")
var rand_num = randi_range(1,50)

# Called when the node enters the scene tree for the first time.
func _ready():
	$CollisionShape3D.scale = Vector3(rand_num,rand_num,rand_num)
	$Meteorite.scale = Vector3(rand_num,rand_num,rand_num)
	$Fire.scale = Vector3(rand_num,rand_num,rand_num)
	self.gravity_scale = Globals.gravity

func _on_body_entered(_body):
	if _body == self:
		return

	var explosion_node = explosion_scene.instantiate()
	explosion_node.position = self.position
	explosion_node.scale = Vector3(rand_num,rand_num,rand_num)
	get_parent().add_child(explosion_node, true)
	self.queue_free()

