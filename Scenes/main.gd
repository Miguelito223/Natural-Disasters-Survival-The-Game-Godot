extends Node3D

func _ready() -> void:
	Globals.main = self
	LoadScene.load_scene(null, "res://Scenes/main_menu.tscn")


func _on_map_spawner_spawned(_node:Node):
	Globals.map = $Map
