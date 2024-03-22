extends Node3D

var explosion_scene = preload("res://Scenes/explosion.tscn")
var lol = [preload("res://Sounds/disasters/nature/closethunder01.mp3"), preload("res://Sounds/disasters/nature/closethunder02.mp3"), preload("res://Sounds/disasters/nature/closethunder03.mp3"), preload("res://Sounds/disasters/nature/closethunder04.mp3"), preload("res://Sounds/disasters/nature/closethunder05.mp3")]


# Called when the node enters the scene tree for the first time.
func _ready():
	$spark.emitting = true
	$spark.one_shot = true
	$spark/light.emitting = true
	$spark/light.one_shot = true
	$spark/light/star.emitting = true
	$spark/light/star.one_shot = true
	$AudioStreamPlayer3D.stream = lol[randi_range(0, lol.size() - 1)]
	$AudioStreamPlayer3D.play()

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

