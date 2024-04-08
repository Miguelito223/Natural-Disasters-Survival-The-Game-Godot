extends CanvasLayer

signal safe_to_load

@onready var Progress_bar = $Control/ProgressBar
@onready var animationplayer = $AnimationPlayer

func update_progress_bar(new_value: float):
	Progress_bar.set_value_no_signal(new_value * 100)

func fade_out_loading_screen():
	animationplayer.play("fade_out")
	await animationplayer.animation_finished
	self.queue_free()
