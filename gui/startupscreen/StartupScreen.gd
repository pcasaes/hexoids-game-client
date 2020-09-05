extends CenterContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	_get_start_button().connect('pressed', self, '_start')
	_get_reset_button().connect('pressed', self, '_reset')
		
	if User.username != null:
		_get_name_edit().text = User.username
		_get_name_edit().caret_position = User.username.length()	

	if _is_name_valid(_get_name_edit().text):
		_get_start_button().grab_focus()
	else:
		_get_name_edit().grab_focus()

	_load_host()
		
	$OutlineBox/VBoxContainer/LinkButton.connect('pressed', self, '_on_source_click')

func _on_source_click():
	OS.shell_open('https://github.com/pcasaes/hexoids')
	
func _load_host():
	_get_server_edit().text = Server.host
		
	
func _start():
	if _is_name_valid(_get_name_edit().text):
		User.username = _get_name_edit().text
		Server.host = _get_server_edit().text
		self.visible = false
		Server.start()
		self.queue_free()	
	
func _reset():
	Server.reset_host()
	_get_name_edit().text = ''
	_load_host()
	_get_name_edit().grab_focus()
	

func _is_name_valid(v):
	return v != null and v.length() >= 3

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _get_name_edit():
	return $OutlineBox/VBoxContainer/GridContainer/NameEdit

func _get_server_edit():
	return $OutlineBox/VBoxContainer/GridContainer/ServerEdit

func _get_start_button():
	return $OutlineBox/VBoxContainer/HBoxContainer/Start

func _get_reset_button():
	return $OutlineBox/VBoxContainer/HBoxContainer/Reset
