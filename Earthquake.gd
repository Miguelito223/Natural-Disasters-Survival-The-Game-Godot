extends Node3D


var shake_strength = 1
var shake_duration = 2
var shake_timer = 0

func _ready():
    start_earthquake(10) # Inicia el terremoto al iniciar la escena

func _process(delta):
    if shake_timer > 0:
        shake_objects(get_tree().get_root())
        shake_timer -= delta

func shake_objects(node):
    for child in node.get_children():
        if child.is_in_group("movable_objects"): # Verifica si el nodo es un Spatial (objeto 3D)
            var x = randi_range(-shake_strength, shake_strength)
            var y = randi_range(-shake_strength, shake_strength)
            var z = randi_range(-shake_strength, shake_strength)
            child.translation += Vector3(x, y, z)

        # Llama recursivamente a la función para procesar los hijos del nodo actual
        if child.get_child_count() > 0:
            shake_objects(child)

func start_earthquake(duration):
    shake_timer = duration