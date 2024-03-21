extends GPUParticles3D


# Called when the node enters the scene tree for the first time.
func _ready():
	await self.finished
	self.queue_free()
