extends Node

const Ship = preload("res://model/players/Ship.tscn")
const Player = preload("res://model/players/Player.tscn")

var store = PlayersStore.new() setget ,get_store


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('player_joined', self, '_on_player_joined')
	Server.connect('player_left', self, '_on_player_left')
	Server.connect('player_moved', self, '_on_player_moved')
	Server.connect('player_spawned', self, '_on_player_spawned')
	Server.connect('player_destroyed', self, '_on_player_destroyed')
	Server.connect('current_view_command', self, '_on_current_view_command')
	Server.connect('server_disconnected', self, '_on_server_disconnected')


func _created(ev):
	var guid = ev.get_playerId().get_guid()
	if !is_instance_valid(store.get(guid)):
		var ship
		var child
		var isUser = User.is_user_from_guid(guid)
		if (isUser):
			store.player = Player.instance()
			ship = store.player.ship()
			child = store.player
		else:
			ship = Ship.instance()
			child = ship
			
		store.set(guid, ship)
		ship.created(ev)
		store.emit_signal('player_created', ship, child, isUser)
		
func _moved(ev):
	var guid = ev.get_playerId().get_guid()
	var ship = store.get(guid)
	if is_instance_valid(ship):
		ship.moved(ev)
		if User.is_user_from_guid(guid):
			store.emit_signal("users_ship_moved", ev, ship)	
		
func _on_player_joined(ev, _dto):
	_created(ev)
	
func _on_server_disconnected():
	var all = store.all().duplicate()
	store.clear()
	for ship in all:
		ship.left()
		
func _on_player_left(ev, _dto):
	var guid = ev.get_playerId().get_guid()
	var ship = store.get(guid)
	if is_instance_valid(ship):
		store.remove(guid)
		ship.left(ev)

func _on_player_destroyed(ev, _dto):
	var guid = ev.get_playerId().get_guid()
	var ship = store.get(guid)
	if is_instance_valid(ship):
		ship.destroyed()
		store.emit_signal('ship_destroyed', ev.get_destroyedById().get_guid(), ship)
		if ship.is_players_ship():
			store.emit_signal('users_ship_destroyed', ev.get_destroyedById().get_guid(), ship)
			
		
func _on_player_spawned(ev, _dto):
	var guid = ev.get_location().get_playerId().get_guid()
	var ship = store.get(guid)
	if is_instance_valid(ship):
		ship.spawned(ev)

func _on_player_moved(ev, _dto):
	_moved(ev)
		
func _on_current_view_command(cmd, _dto):
	for r in cmd.get_players():
		_created(r)
		_moved(r)
				

func get_store():
	return store
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


class PlayersStore:
	
	signal player_created
	signal ship_destroyed
	signal users_ship_destroyed
	signal users_ship_moved
	
	var players = {}
	
	var player
	
	func set(guid, p):
		players[guid] = p
		
	func remove(guid):
		players.erase(guid)
		
	func get(uuid):
		return players.get(uuid)
		
	func all():
		return players.values()
		
	func clear():
		players.clear()
