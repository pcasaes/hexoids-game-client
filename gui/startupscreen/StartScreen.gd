extends PanelContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

	
# Called when the node enters the scene tree for the first time.
func _ready():
	_get_start_button().connect('pressed', self, '_start')
	_get_reset_button().connect('pressed', self, '_reset')
	_get_source_button().connect('pressed', self, '_on_source_click')
	_get_download_button().connect('pressed', self, '_on_download_click')
	connect("visibility_changed", self, "_on_visibilty_changed")
	
	if Server.can_change_host():
		_get_server_edit().visible = true
		_get_server_label().visible = true

func _on_visibilty_changed():
	if visible:
		if User.username != null:
			_get_name_edit().text = User.username
			_get_name_edit().caret_position = User.username.length()	
	
		if _is_name_valid(_get_name_edit().text):
			_get_start_button().grab_focus()
		else:
			_get_name_edit().grab_focus()
			
		_load_host()
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _is_name_valid(v):
	return v != null and v.length() >= 3


func _start():
	if _is_name_valid(_get_name_edit().text):
		User.username = _get_name_edit().text
		var hostChanged = Server.host != _get_server_edit().text 
		Server.host = _get_server_edit().text
		if hostChanged:
			Server.request_clients_available()
		else:
			Server.start()
func _on_download_click():
	Server.open_download_page()
	
func _on_source_click():
	OS.shell_open('https://github.com/pcasaes/hexoids')

func _load_host():
	_get_server_edit().text = Server.host
	
func _reset():
	_get_name_edit().text = ''
	_get_name_edit().grab_focus()
	
	if Server.can_change_host():
		Server.reset_host()
		_load_host()
	
func _get_name_edit():
	return $VBoxContainer/GridContainer/NameEdit

func _get_server_edit():
	return $VBoxContainer/GridContainer/ServerEdit

func _get_server_label():
	return $VBoxContainer/GridContainer/ServerLabel

func _get_start_button():
	return $VBoxContainer/HBoxContainer/Start

func _get_reset_button():
	return $VBoxContainer/HBoxContainer/Reset

func _get_source_button():
	return $VBoxContainer/SourceLink

func _get_download_button():
	return $VBoxContainer/DownloadLink
