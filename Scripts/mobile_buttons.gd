extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Globals.is_networking:
		if not is_multiplayer_authority():
			self.visible = is_multiplayer_authority()
			return

	self.visible = true
