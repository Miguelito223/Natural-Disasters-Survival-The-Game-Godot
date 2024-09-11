extends CanvasLayer

@onready var grid = $Panel/grid
@onready var player = get_parent()
@export var spawnlist: Array[Node]
@export var buttonlist: Array[Button]

func _ready():
	
	var directory = DirAccess.open("res://Scenes/")
	if directory:
		var files = directory.get_files()
		for i in files:
			print(directory.get_current_dir() + "/" + i)
			var node = load(directory.get_current_dir() + "/" + i).instantiate()
			if node.get_class() == "RigidBody3d":
				spawnlist.append(node)

	for i in spawnlist:
		var button = Button.new()
		button.text = i.text
		button.pressed.connect("spawn", Spawn)
		buttonlist.append(button)
		grid.add_child(button)

func Spawn():
	for i in spawnlist:
		for j in buttonlist:
			if i.text == j.text:
				player.get_parent().add_child(i)

		

func _process(_delta):
	pass
	
