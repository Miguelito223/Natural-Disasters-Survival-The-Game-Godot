extends CanvasLayer

func _ready():
	if Globals.is_networking:
		if not is_multiplayer_authority():
			self.visible = is_multiplayer_authority()
			return

	self.visible = false

func _process(_delta):
	if Globals.is_networking:
		
		if not is_multiplayer_authority():
			return


		# Eliminar todos los hijos del VBoxContainer
		for child in $List.get_children():
			$List.remove_child(child)

		# Iterar sobre los jugadores conectados y agregarlos a la lista
		if not Globals.players_conected_array.is_empty():
			for player_data in Globals.players_conected_array:
				if is_instance_valid(player_data):
					var label = Label.new()
					label.text = player_data.username + " points: " + str(player_data.points)
					$List.add_child(label, true)

		# Mostrar u ocultar la lista de jugadores según la acción del teclado
		if Input.is_action_just_pressed("List of players"):
			self.visible = !self.visible
