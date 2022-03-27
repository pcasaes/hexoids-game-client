extends CenterContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var store = GUIStore.store

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('player_left', self, '_on_player_left')
	Server.connect('server_disconnected', self, '_on_server_disconnected')
	Server.connect('server_connected', self, '_on_server_connected')
	$Start.connect('pressed', self, '_start')

func _on_player_left(ev, _dto):
	if User.is_user_from_guid(ev.get_playerId().get_guid()):
		_on_server_disconnected()

func _on_server_disconnected():
	self.visible = true
		
func _on_server_connected():
	self.visible = false
		
func _on_player_destroyed(ev, _dto):
	if User.is_user_from_guid(ev.get_playerId().get_guid()):
		self.visible = true
	
func _start():
	Server.start()		
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
