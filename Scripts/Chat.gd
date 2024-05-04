extends CanvasLayer



var history: Array[String] = []
var history_index: int = -1
var autocomplete_index: int = 0
# All methods that are viable for autocomplete
var autocomplete_methods: Array = []
# Track if that last input was related to autocomplete
var last_input_was_autocomplete: bool = false
# Store matches of the last autocomplete so that the search doesn't have to be repeated
# when Tab is pressed multiple times
var prev_autocomplete_matches: Array = []

var matches = []
@onready var match_string = $LineEdit.text.erase(0,1)

func _ready() -> void:
	self.visible = true
	autocomplete_methods = Globals.map.get_script().get_script_method_list().map(func (x): return x.name)	

func _input(_event: InputEvent) -> void:
	if $LineEdit.text.begins_with("/"):
		last_input_was_autocomplete = Input.is_action_just_pressed('dev_console_autocomplete') \
			or Input.is_action_just_released('dev_console_autocomplete')

		if Input.is_action_just_released('dev_console_autocomplete'):
			autocomplete()

		if Input.is_action_just_pressed('_dev_console_enter'):
			history.push_front($LineEdit.text.erase(0, 1))
			
			if Globals.is_networking:
				msg_rpc.rpc(Globals.username, $LineEdit.text)
			else:
				msg_rpc(Globals.username, $LineEdit.text)

			history_index = -1
			$LineEdit.text = ''
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
	
@rpc("any_peer", "call_local")
func _run_command(cmd: String) -> void:
	# Create an Expression instance
	var expression = Expression.new()
	var parse_error = expression.parse(cmd)
	if parse_error != OK:
		$TextEdit.text += expression.get_error_text() + "\n"
		$TextEdit.scroll_vertical =  $TextEdit.get_line_height()
		return

	var result = expression.execute([], Globals.map)

	if expression.has_execute_failed():
		$TextEdit.text += expression.get_error_text() + "\n"
		$TextEdit.scroll_vertical =  $TextEdit.get_line_height()
		return
	elif result != null:
		if not result is Object:
			$TextEdit.text += str(result) + "\n"
			$TextEdit.scroll_vertical =  $TextEdit.get_line_height()

func autocomplete() -> void:

	# Run through matches for the last string if the user is stepping through autocomplete options
	if last_input_was_autocomplete:
		matches = prev_autocomplete_matches
	# Step through all possible matches if no input string
	elif match_string.is_empty():
		matches = autocomplete_methods
	# Otherwise check if each possible method begins with the user string
	else:
		for method in autocomplete_methods:
			if method.begins_with(match_string):
				matches.append(method)

	# Store matches string for later
	prev_autocomplete_matches = matches

	# Nothing to return if no matches
	if matches.size() == 0:
		return

	# Go to the next possible autocomplete option if the user is Tabbing through options
	if last_input_was_autocomplete:
		autocomplete_index = wrapi(
			autocomplete_index + 1,
			0,
			matches.size()
		)
	else:
		autocomplete_index = 0

	# Populate console input with match
	$LineEdit.text = "/" + matches[autocomplete_index]
	# Make sure the caret goes to the end of the line
	$LineEdit.caret_column = 100000

@rpc("any_peer", "call_local")
func msg_rpc(username, data):

	if data != "" or data != " ":
		$TextEdit.text +=  str(username, ": ", data, "\n")
	$TextEdit.scroll_vertical =  $TextEdit.get_line_height()

	if Globals.is_networking:
		if data.begins_with("/") and multiplayer.is_server():
			data = data.erase(0, 1)
			print(data)
			_run_command.rpc(data)
		elif data.begins_with("/") and !multiplayer.is_server():
			$TextEdit.text +=  "You are not a admin... \n"	
	else:
		if data.begins_with("/"):
			data = data.erase(0, 1)
			print(data)
			_run_command(data)	

	

func _on_button_pressed():
	if Globals.is_networking:
		msg_rpc.rpc(Globals.username, $LineEdit.text)
	else:
		msg_rpc(Globals.username, $LineEdit.text)
	
	$LineEdit.text = ""
