extends MarginContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('server_connected', self, '_on_server_connected')
	get_tree().get_root().connect("size_changed", self, "_on_resize")
	_on_resize()

func _on_resize():
	self.rect_min_size = Vector2(0, get_viewport_rect().size.y-16)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_server_connected():
	$HUD.visible = true
