extends Node3D

var shake_strength = 1

func shake_objects(node):
    for child in node.get_children():
        if child.is_class("Spatial"): # Verifica si el nodo es un Spatial (objeto 3D)
            var x = randi_range(-shake_strength, shake_strength)
            var y = randi_range(-shake_strength, shake_strength)
            var z = randi_range(-shake_strength, shake_strength)
            child.position += Vector3(x, y, z)

        # Llama recursivamente a la función para procesar los hijos del nodo actual
        if child.get_child_count() > 0:
            shake_objects(child)
