extends RigidBody3D

var explosion_scene = preload("res://Scenes/explosion.tscn")
var rand_num = randi_range(1,50)
var is_volcano_rock = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if not is_volcano_rock:
		$CollisionShape3D.scale = Vector3(rand_num,rand_num,rand_num)
		$Meteorite.scale = Vector3(rand_num,rand_num,rand_num)
		$Fire.process_material.emission_sphere_radius = rand_num
		$Fire/Smoke.process_material.emission_sphere_radius = rand_num
		self.gravity_scale = Globals.gravity
	else:
		self.gravity_scale = Globals.gravity

func _on_body_entered(_body):
	if _body == self:
		return

	var explosion_node = explosion_scene.instantiate()
	explosion_node.position = self.position
	explosion_node.process_material.emission_sphere_radius = rand_num
	explosion_node.get_node("Area3D/CollisionShape3D").shape.radius = rand_num
	get_parent().add_child(explosion_node, true)
	self.queue_free()

