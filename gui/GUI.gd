extends MarginContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().get_root().connect("size_changed", self, "_on_resize")

func _on_resize():
	$HUD.rect_min_size = Vector2(0, get_viewport_rect().size.y-16)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
