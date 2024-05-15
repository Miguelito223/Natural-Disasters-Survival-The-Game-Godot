extends CanvasLayer



var history: Array[String] = []
var history_index: int = -1

var autocomplete_methods: Array = []

func _enter_tree():
	if Globals.is_networking:
		set_multiplayer_authority(multiplayer.get_unique_id())

func _ready() -> void:
	if Globals.is_networking:
		if not is_multiplayer_authority():
			self.visible = is_multiplayer_authority()
			return

	self.visible = true
	autocomplete_methods = get_parent().get_script().get_script_method_list().map(func (x): return x.name)	



func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed('Select Chat'):
		$LineEdit.grab_focus()
		$LineEdit.text = ""

	if $LineEdit.text.begins_with("/"):
		if Input.is_action_just_pressed('dev_console_autocomplete'):
			for method in autocomplete_methods:
				if method.begins_with($LineEdit.text.erase(0,1)):
					# Populate console input with match
					$LineEdit.text = "/" + method
					# Make sure the caret goes to the end of the line
					$LineEdit.caret_column = 100000

		if Input.is_action_just_pressed('_dev_console_enter'):
			history.push_front($LineEdit.text.erase(0, 1))
			
			if Globals.is_networking:
				if not is_multiplayer_authority():
					return
					
				if $LineEdit.text.begins_with("/"):
					msg_rpc(Globals.username, $LineEdit.text)
				else:
					msg_rpc.rpc(Globals.username, $LineEdit.text)
			else:
				msg_rpc(Globals.username, $LineEdit.text)

			history_index = -1
			$LineEdit.text = ""
			$LineEdit.release_focus()
			$Button.release_focus()
		elif Input.is_action_just_released('_dev_console_prev'):
			if history.size() == 0:
				return
			history_index = clamp(history_index + 1, 0, history.size() - 1)
			$LineEdit.text = "/" + history[history_index]
			# Hack to make the caret go to the end of the line
			# If I ever have a line of code over 100k characters, please send help
			$LineEdit.caret_column = 100000
		elif Input.is_action_just_released('_dev_console_next'):
			if history.size() == 0:
				return
			history_index = clamp(history_index - 1, 0, history.size() - 1)
			$LineEdit.text = "/" + history[history_index]
			$LineEdit.caret_column = 100000

	else:
		if Input.is_action_just_pressed('Enter'):
			if Globals.is_networking:
				if not is_multiplayer_authority():
					return

				msg_rpc.rpc(Globals.username, $LineEdit.text)
			else:
				msg_rpc(Globals.username, $LineEdit.text)

			$LineEdit.text = ""
			$LineEdit.release_focus()
			$Button.release_focus()
	
@rpc("any_peer", "call_local")
func _run_command(cmd: String) -> void:
	# Create an Expression instance
	var expression = Expression.new()
	var parse_error = expression.parse(cmd)
	if parse_error != OK:
		$TextEdit.text += expression.get_error_text() + "\n"
		$TextEdit.scroll_vertical =  $TextEdit.get_line_height()
		return

	var result = expression.execute([], get_parent())

	if expression.has_execute_failed():
		$TextEdit.text += expression.get_error_text() + "\n"
		$TextEdit.scroll_vertical =  $TextEdit.get_line_height()
		return
	elif result != null:
		if not result is Object:
			$TextEdit.text += str(result) + "\n"
			$TextEdit.scroll_vertical =  $TextEdit.get_line_height()

@rpc("any_peer", "call_local")
func msg_rpc(username, data):
	if Globals.is_networking:
		if data.begins_with("/"):
			if multiplayer.is_server() and is_multiplayer_authority():
				if data != "" or data != " ":
					$TextEdit.text += str(username, ": ", data, "\n")
					$TextEdit.scroll_vertical =  $TextEdit.get_line_height()
				data = data.erase(0, 1)
				print(data)
				_run_command.rpc(data)
			else:
				$TextEdit.text +=  "You are not a have admin... \n"	
				$TextEdit.scroll_vertical =  $TextEdit.get_line_height()
		else:
			if data != "" or data != " ":
				$TextEdit.text += str(username, ": ", data, "\n")
				$TextEdit.scroll_vertical =  $TextEdit.get_line_height()
	else:
		if data.begins_with("/"):
			if data != "" or data != " ":
				$TextEdit.text += str(username, ": ", data, "\n")
				$TextEdit.scroll_vertical =  $TextEdit.get_line_height()
			data = data.erase(0, 1)
			print(data)
			_run_command(data)
		else:
			if data != "" or data != " ":
				$TextEdit.text += str(username, ": ", data, "\n")
				$TextEdit.scroll_vertical =  $TextEdit.get_line_height()	

	

func _on_button_pressed():
	if Globals.is_networking:
		if not is_multiplayer_authority():
			return

		if $LineEdit.text.begins_with("/"):
			msg_rpc(Globals.username, $LineEdit.text)
		else:
			msg_rpc.rpc(Globals.username, $LineEdit.text)
	else:
		msg_rpc(Globals.username, $LineEdit.text)
	
	$LineEdit.text = ""
	$LineEdit.release_focus()
	$Button.release_focus()
