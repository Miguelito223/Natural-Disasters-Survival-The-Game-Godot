extends Node3D

var explosion_scene = preload("res://Scenes/explosion.tscn")
var lol = [preload("res://Sounds/disasters/nature/closethunder01.mp3"), preload("res://Sounds/disasters/nature/closethunder02.mp3"), preload("res://Sounds/disasters/nature/closethunder03.mp3"), preload("res://Sounds/disasters/nature/closethunder04.mp3"), preload("res://Sounds/disasters/nature/closethunder05.mp3")]
@onready var raycast = $RayCast3D

# Called when the node enters the scene tree for the first time.
func _ready():
	# Configurar la posición de la explosión en la posición del suelo
	var explosion = explosion_scene.instantiate()
	explosion.position = self.position
	get_parent().add_child(explosion)
	
	# Configurar el sonido del trueno
	$AudioStreamPlayer3D.stream = lol[randi_range(0, lol.size() - 1)]
	$AudioStreamPlayer3D.play()
	
	# Reproducir el efecto visual del rayo
	$spark.emitting = true
	$spark.one_shot = true
	$spark/light.emitting = true
	$spark/light.one_shot = true
	$spark/light/star.emitting = true
	$spark/light/star.one_shot = true

func _on_spark_finished():
	self.queue_free()