extends Node

func _ready() -> void:
	_generate_icon()

func _generate_icon():
	for child in get_children():
		await RenderingServer.frame_post_draw
		var img = child.get_texture().get_image()
		img.save_png("res://icons/" + child.name +".png")