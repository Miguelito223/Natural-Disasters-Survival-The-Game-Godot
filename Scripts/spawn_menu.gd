extends CanvasLayer

@onready var grid = $Panel/grid
@export var spawnlist: Array[Node]
@export var buttonlist: Array[Button]
@export var spawnedobject: Array[Node]
var spawnmenu_state = false

func _ready():

	self.visible = false
	load_spawnlist_entities()
	load_buttons()


func load_spawnlist_entities():
	var directory = DirAccess.open("res://Scenes/")
	if directory:
		var files = directory.get_files()
		for i in files:
			if i.ends_with(".tscn"):
				var node = load(directory.get_current_dir() + "/" + i).instantiate()
				if node.get_class() == "RigidBody3D":
					spawnlist.append(node)
			else:
				print("i cant import that")
				return

func load_buttons():
	for i in spawnlist:
		var button = Button.new()
		button.text = i.name
		button.add_theme_font_size_override("FontSize", 50)
		button.icon = load("res://icons/" + i.name + "_icon.png")
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.pressed.connect(func(): on_press(i))
		buttonlist.append(button)
		grid.add_child(button)

func on_press(i: Node):
	if Globals.is_networking:
		if not multiplayer.is_server():
			print("You not a host")
			return

	var marker = Globals.local_player.get_node("Model/Spawner")
	var spawn_position = marker.global_transform.origin
	i.global_transform.origin = spawn_position
	var new_i = i.duplicate()
	spawnedobject.append(new_i)
	Globals.map.add_child(new_i)




func spawnmenu():
	self.visible = spawnmenu_state
	
	if spawnmenu_state:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if not Globals.is_networking:
			get_tree().paused = true
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if not Globals.is_networking:
			get_tree().paused = false

	spawnmenu_state = !spawnmenu_state

func remove():
	for i in spawnedobject:
		if is_instance_valid(i) and spawnedobject.find(i) >= spawnedobject.size():
			i.queue_free()


func _process(_delta):
	if Input.is_action_just_pressed("Spawnmenu"):
		spawnmenu()

	if Input.is_action_pressed("Remove"):
		remove()