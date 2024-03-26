extends Node3D


func _on_map_spawner_spawned(node:Node):
	Globals.map = get_node("Map")
