extends Node3D

var bounding_radius_area = null
@onready var door = $Room/Door_Group/DoorFrame/Door
@onready var room = $Room
@onready var Techo = $Room/Techo
@onready var Suelo = $Room/Suelo
@onready var Baseboard = $Room/Baseboard
@onready var door_open_sound = $Open_door_sound
@onready var door_close_sound = $Close_door_sound
var door_open = false


func open_door():
	door.rotation.y = lerp_angle(door.rotation.y, deg_to_rad(145), 0.005)
	door_open = true

func close_door():
	door.rotation.y = lerp_angle(door.rotation.y, deg_to_rad(0), 0.005)
	door_open = false


func _on_interactable_interacted(_interactor:Interactor) -> void:
	print("Open the door!!")
	if not door_open:
		open_door()
	else:
		close_door()


func _on_interactable_focused(_interactor:Interactor) -> void:
	print("Press e to interact")


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("movable_objects") and body.is_class("RigidBody3D"):
		if body.linear_velocity.x > 30 or body.linear_velocity.y > 30 or body.linear_velocity.z > 130:
			$Destruction.destroy(0)
		
		if self.linear_velocity.x > 10 or self.linear_velocity.y > 10 or self.linear_velocity.z > 10:
			$Destruction.destroy(0)
	else:
		if self.linear_velocity.x > 10 or self.linear_velocity.y > 10 or self.linear_velocity.z > 10:
			$Destruction.destroy(0)