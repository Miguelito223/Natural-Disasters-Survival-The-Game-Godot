extends Node3D

func _ready() -> void:
	Globals.main = self


func _on_map_spawner_spawned(_node:Node):
	Globals.map = $Map
