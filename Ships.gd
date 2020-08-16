extends Node2D


# Declare member variables here. Examples:
export (PackedScene) var Ship
export (PackedScene) var Player

var players = PlayersStore.store
var main
var player

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('player_joined', self, '_on_player_joined')
	Server.connect('player_left', self, '_on_player_left')
	Server.connect('player_moved', self, '_on_player_moved')
	Server.connect('player_spawned', self, '_on_player_spawned')
	Server.connect('player_destroyed', self, '_on_player_destroyed')
	Server.connect('players_list_command', self, '_on_players_list_command')



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _created(ev):
	var guid = ev.get_playerId().get_guid()
	if players.get(guid) == null:
		var ship
		var child
		if (guid == User.getId()):
			player = Player.instance()
			ship = player.ship()
			child = player
		else:
			ship = Ship.instance()
			child = ship
			
		players.set(guid, ship)
		ship.created(ev)
		add_child(child)
		ship._on_Main_main_ready(main)

func _moved(ev):
	var guid = ev.get_playerId().get_guid()
	var ship = players.get(guid)
	if ship != null:
		ship.moved(ev)


func _on_player_joined(ev, _dto):
	_created(ev)
		
func _on_player_left(ev, _dto):
	var guid = ev.get_playerId().get_guid()
	var ship = players.get(guid)
	if ship != null:
		ship.left(ev)
		players.remove(guid)

func _on_player_destroyed(ev, _dto):
	var guid = ev.get_playerId().get_guid()
	var ship = players.get(guid)
	if ship != null:
		ship.destroyed()
		
func _on_player_spawned(ev, _dto):
	var guid = ev.get_location().get_playerId().get_guid()
	var ship = players.get(guid)
	if ship != null:
		ship.spawned(ev)

func _on_player_moved(ev, _dto):
	_moved(ev)
		
func _on_players_list_command(cmd, _dto):
	for r in cmd.get_players():
		_created(r)
		_moved(r)
		


func _on_Main_main_ready(m):
	main = m
	for s in players.all():
		s._on_Main_main_ready(m)
