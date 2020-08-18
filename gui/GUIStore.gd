extends Node

var store = GUIStore.new() setget ,get_store


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_store():
	return store
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


class GUIStore:
	var players = {}
	var myPlayerId
	
	func _init():
		Server.connect('player_joined', self, '_on_player_joined')
		Server.connect('player_left', self, '_on_player_left')
		Server.connect('players_list_command', self, '_on_players_list_command')
		Server.connect('server_disconnected', self, '_on_server_disconnected')

	
	func _on_server_disconnected():
		players.clear()
		
	func _on_player_left(ev, _dto):
		players.erase(ev.get_playerId().get_guid())
	
	func _on_player_joined(ev, _dto):
		addPlayer(ev)
	
	func _on_players_list_command(cmd, dto):
		myPlayerId = dto.get_directedCommand().get_playerId().get_guid()
		for r in cmd.get_players():
			addPlayer(r)
		
	func toFixedWithName(name, length, chr):
		if name.length() > length:
			return name.substr(0, length)
			
		while (name.length() < length):
			name += chr
		
		return name;	
	
	func addPlayer(p):
		var lbPlayer = GUIPlayerInfo.new()
		lbPlayer.color = HexoidsColors.get(p.get_ship()).lighterColor
		lbPlayer.name = p.get_name()
		lbPlayer.displayName = toFixedWithName(p.get_name(), HexoidsConfig.world.hud.nameLength, ' ').to_upper()
		players[p.get_playerId().get_guid()] = lbPlayer

	
	func remove(guid):
		players.erase(guid)
		
	func get(uuid):
		return players.get(uuid)
		
	func all():
		return players.values()
		
	func clear():
		players.clear()
		
	func getMyPlayerId():
		return myPlayerId;

class GUIPlayerInfo:
	var name
	var displayName
	var color
	
