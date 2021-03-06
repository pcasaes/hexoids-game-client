extends CenterContainer

const HexoidsProto = preload("res://server/HexoidsProto.gd")


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var store = GUIStore.store

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('player_spawned', self, '_on_player_spawned')
	Server.connect('player_destroyed', self, '_on_player_destroyed')
	Server.connect('player_left', self, '_on_player_left')
	Server.connect('server_disconnected', self, '_on_server_disconnected')
	$Start.connect('pressed', self, '_start')
	
func _on_player_spawned(ev, _dto):
	if store.getMyPlayerId() == ev.get_location().get_playerId().get_guid():
		self.visible = false

func _on_player_left(ev, _dto):
	if store.getMyPlayerId() == ev.get_playerId().get_guid():
		self.visible = false

func _on_server_disconnected():
	self.visible = false		
		
func _on_player_destroyed(ev, _dto):
	if store.getMyPlayerId() == ev.get_playerId().get_guid():
		self.visible = true
		$Start.grab_focus()
	
func _start():
		var request = HexoidsProto.RequestCommand.new()
		request.new_spawn()				
		Server.sendMessage(request)
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
