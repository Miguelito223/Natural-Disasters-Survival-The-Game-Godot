extends Node

signal progress_changed(progress)
signal unload_done

const GAME_SCENE ={
	"map": "res://Scenes/map.tscn",
}

var unloading_screen_path: String = "res://Scenes/loading_screen.tscn"
var unloading_screen = load(unloading_screen_path)
var unloader_resource: PackedScene
var scene
var scene_path: String
var progress: Array = []

var use_sub_theads: bool = false

func unload_scene(current_scene):
	if current_scene != null:
		scene_path = current_scene.scene_file_path
		scene = current_scene

	print(scene_path)

	var unloading_screen_scene = unloading_screen.instantiate()
	Globals.main.add_child(unloading_screen_scene)
	
	self.progress_changed.connect(unloading_screen_scene.update_progress_bar)
	self.unload_done.connect(unloading_screen_scene.fade_out_loading_screen)

	await Signal(unloading_screen_scene, "safe_to_load")

	if current_scene != null:
		current_scene.queue_free()

	start_load()


func start_load():
	if GAME_SCENE.has(scene_path):
		scene_path = GAME_SCENE[scene_path]
	else:
		scene_path = scene_path

	var loader_next_scene = ResourceLoader.load_threaded_request(scene_path, "", use_sub_theads)
	if loader_next_scene == OK:
		set_process(true)


func _process(_delta):
	var load_status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	match load_status:
		0,2:
			print("failed to load")
			set_process(false)
			return
		1:
			emit_signal("progress_changed", progress[0])
		3:
			emit_signal("progress_changed", 1.0)
			emit_signal("unload_done")

