extends PanelContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var _clientVer

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect("client_version", self, "_on_client_version")
	if OS.get_name() == 'HTML5':
		$VBoxContainer/Label.text = "Please clear your brower's cache or download a native client"

	$VBoxContainer/LinkButton.connect('pressed', self, '_on_download_click')

func _on_client_version(ver):
	_clientVer = ver
	$VBoxContainer/LinkButton.visible = true

func _on_download_click():
	Server.open_download_page()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
