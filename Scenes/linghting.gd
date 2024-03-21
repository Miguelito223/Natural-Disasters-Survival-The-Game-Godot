extends Node3D

var explosion_scene = preload("res://Scenes/explosion.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	$spark.one_shot = true
	$spark/light.one_shot = true
	$spark/light/star.one_shot = true

	var explosion = explosion_scene.instantiate()
	explosion.position = self.position
	add_child(explosion, true)

	await $spark.finished
	self.queue_free()

	await explosion.finished
	explosion.queue_free()





func _on_area_3d_body_entered(body:Node3D):
	if body.is_in_group("player"):
		body.damage(20)

