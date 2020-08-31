extends CenterContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	_get_line_edit().connect('gui_input', self, '_on_name_set')
	_get_line_edit().grab_focus()
	if User.username != null:
		_get_line_edit().text = User.username
		_get_line_edit().caret_position = User.username.length()	
	
	
func _on_text_changed(newtext):
	print(newtext)
	
func _on_name_set(ev):
	if ev is InputEventKey and ev.is_pressed() and ev.scancode == KEY_ENTER:
		if _get_line_edit().text.length() >= 3:
			User.username = _get_line_edit().text
			self.visible = false
			Server.start()
			self.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _get_line_edit():
	return $OutlineBox/VBoxContainer/HBoxContainer/LineEdit
