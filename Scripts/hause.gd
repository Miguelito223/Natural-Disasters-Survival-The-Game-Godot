extends Node3D

@onready var door = $Room/Door_Group/DoorFrame/Door
@onready var door_collisions = $DoorCollision
@onready var room = $Room
@onready var Techo = $Room/Techo
@onready var Suelo = $Room/Suelo
@onready var Baseboard = $Room/Baseboard
@onready var door_open_sound = $Open_door_sound
@onready var door_close_sound = $Close_door_sound
var door_open = false

@rpc("any_peer", "call_local")
func open_door():
	print("Open the door!!")
	door.rotation.y = deg_to_rad(145)
	door_collisions.rotation.y = deg_to_rad(145)
	door_open = true

@rpc("any_peer", "call_local")
func close_door():
	print("Close the door!!")
	door.rotation.y = deg_to_rad(0)
	door_collisions.rotation.y = deg_to_rad(0)
	door_open = false


func _on_interactable_interacted(_interactor:Interactor) -> void:
	if Globals.is_networking:
		if not door_open:
			open_door.rpc()
		else:
			close_door.rpc()
	else:
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
