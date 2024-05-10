@tool
extends EditorScript

func _run():
	var group_name = "movable_objects"
	var group_name2 = "wind_effected_objects"
	var nodes = []

	# Obtener la selección del editor
	var selection = EditorInterface.get_selection().get_selected_nodes()

	# Filtrar solo los nodos que se pueden agregar a grupos
	for node in selection:
		if node is Node:
			nodes.append(node)

	# Agregar los nodos al grupo
	for node in nodes:
		node.add_to_group(group_name)
		node.add_to_group(group_name2)
