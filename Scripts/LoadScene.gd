extends Node

signal progress_changed(progress)
signal load_done

const GAME_SCENE ={
	"map": "res://Scenes/map_1.tscn",
}

var loading_screen_path: String = "res://Scenes/loading_screen.tscn"
var loading_screen = load(loading_screen_path)
var loader_resource: PackedScene
var scene_path: String
var progress: Array = []

var use_sub_theads: bool = false

func load_scene(current_scene, next_scene):

	if next_scene != null:
		scene_path = next_scene

	var loading_screen_intance = loading_screen.instantiate()
	Globals.main.add_child(loading_screen_intance)
	
	self.progress_changed.connect(loading_screen_intance.update_progress_bar)
	self.load_done.connect(loading_screen_intance.fade_out_loading_screen)

	await Signal(loading_screen_intance, "safe_to_load")

	if current_scene != null and is_instance_valid(current_scene):
		current_scene.queue_free()

	if GAME_SCENE.has(scene_path):
		scene_path = GAME_SCENE[scene_path]
	else:
		scene_path = scene_path
	
	var loader_next_scene = ResourceLoader.load_threaded_request(scene_path, "", use_sub_theads)
	if loader_next_scene == OK:
		print("is ok")
		set_process(true)


func _process(_delta):
	var load_status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	match load_status:
		0:
			print("failed to load: invalid resource")
			set_process(false)
			return
		2:
			print("failed to load")
			set_process(false)
			return
		1:
			emit_signal("progress_changed", progress[0])
		3:
			print("Completed")
			
			if scene_path == "res://Scenes/main.tscn":
				pass
			else:
				var new_scene = ResourceLoader.load_threaded_get(scene_path).instantiate()
				if is_instance_valid(new_scene):
					Globals.main.add_child(new_scene)
			
			emit_signal("progress_changed", 1.0)
			emit_signal("load_done")
			set_process(false)
