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
	signal my_player_joined

	var items = {}
	var myPlayerId
	
	func _init():
		Server.connect('player_joined', self, '_on_player_joined')
		Server.connect('player_left', self, '_on_player_left')
		Server.connect('current_view_command', self, '_on_current_view_command')
		Server.connect('server_disconnected', self, '_on_server_disconnected')
		BlackholeStore.connect('blackhole_event', self, '_on_blackhole_event')

	
	func _on_server_disconnected():
		items.clear()
		
	func _on_player_left(ev, _dto):
		items.erase(ev.get_playerId().get_guid())

	func _on_player_joined(ev, _dto):
		addPlayer(ev)
	
	func _on_current_view_command(cmd, dto):
		myPlayerId = dto.get_directedCommand().get_playerId().get_guid()
		for r in cmd.get_players():
			addPlayer(r)
			
	func _on_blackhole_event(ev, started):
		if started:
			var lbItems = GUIItemInfo.new()
			lbItems.id = ev.get_id().get_guid()
			lbItems.color = Color(0.9,0.9,0.9,1)
			lbItems.name = ev.get_name()
			lbItems.displayName = toFixedWithName(ev.get_name(), HexoidsConfig.world.hud.nameLength, ' ').to_upper()
			items[ev.get_id().get_guid()] = lbItems
		else:
			remove(ev.get_id().get_guid())
		
	func toFixedWithName(name, length, chr):
		if name.length() > length:
			return name.substr(0, length)
			
		while (name.length() < length):
			name += chr
		
		return name;	
	
	func addPlayer(p):
		var lbItems = GUIItemInfo.new()
		lbItems.id = p.get_playerId().get_guid()
		lbItems.color = HexoidsColors.get(p.get_ship()).lighterColor
		lbItems.name = p.get_name()
		lbItems.displayName = toFixedWithName(p.get_name(), HexoidsConfig.world.hud.nameLength, ' ').to_upper()
		items[p.get_playerId().get_guid()] = lbItems
		if p.get_playerId().get_guid() == myPlayerId:
			emit_signal('my_player_joined', lbItems)
	
	func remove(guid):
		items.erase(guid)
		
	func get(uuid):
		return items.get(uuid)
		
	func all():
		return items.values()
		
	func clear():
		items.clear()
		
	func getMyPlayerId():
		return myPlayerId


class GUIItemInfo:
	var id
	var name
	var displayName
	var color
	
