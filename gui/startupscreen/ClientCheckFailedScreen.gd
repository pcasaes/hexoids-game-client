extends PanelContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	_get_try_gain_button().connect('pressed', self, '_on_try_again_clicked')
	_get_reset_button().connect('pressed', self, '_on_reset')
	connect("visibility_changed", self, "_on_visibilty_changed")

	if Server.can_change_host():
		$VBoxContainer/GridContainer.visible = true
		_get_reset_button().visible = true

func _on_visibilty_changed():
	if visible:
		_load_host()
		_get_server_edit().grab_focus()
	
func _on_try_again_clicked():
	Server.request_clients_available(_get_server_edit().text)
	
func _on_reset():
	if Server.can_change_host():
		Server.reset_host()
		_load_host()
	
func _load_host():
	_get_server_edit().text = Server.host
	

func _get_try_gain_button():
	return $VBoxContainer/HBoxContainer/TryAgain
	
func _get_reset_button():
	return $VBoxContainer/HBoxContainer/Reset
	
func _get_server_edit():
	return $VBoxContainer/GridContainer/ServerEdit
