extends CanvasLayer

@onready var grid = $Panel/grid
@onready var player = get_parent()
@export var spawnlist: Array[Node]
@export var buttonlist: Array[Button]
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

	var player_position = player.global_transform.origin
	var player_forward_vector = player.global_transform.basis.z
	player_forward_vector = player_forward_vector.normalized()
	var spawn_position = player_position
	spawn_position += player_forward_vector * 100
	i.global_transform.origin = spawn_position
	var new_i = i.duplicate()
	player.get_parent().add_child(new_i)	




func spawnmenu():
	if Input.is_action_pressed("Spawnmenu"):

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

func _process(_delta):
	spawnmenu()