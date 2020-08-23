extends Node

const HexoidsProto = preload("res://server/HexoidsProto.gd")

signal server_disconnected
signal server_connected

# domain events
signal bolt_exhausted
signal bolt_fired
signal player_fired
signal player_destroyed
signal player_joined
signal player_left
signal player_moved
signal player_spawned
signal player_score_increased
signal player_score_updated
signal score_board_updated

# directed commands
signal players_list_command
signal player_score_update_command
signal live_bolts_list_command

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var client
var connected = false;
var joinTime

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _init():
	client = WebSocketClient.new()

	client.connect("connection_established", self, "_on_opened")
	client.connect("connection_closed", self, "_on_closed")
	client.connect("connection_error", self, "_on_error")
	client.connect("data_received", self, "_on_received")

func start():
	print("Starting server for user " + User.getId())
	var endpoint = 'ws://daedalus:28080/game/' + User.getId()
	var err = client.connect_to_url(endpoint)
	print("Connection status: " + str(err))
	
func _on_opened(_protocol):
	client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_BINARY)
	connected = true
	print("connected to host")
	joinTime = HClock.clock.clientTime()
	var request = HexoidsProto.RequestCommand.new()
	request.new_join().set_name(User.getUsername())
	
	sendMessage(request)
	emit_signal("server_connected")
	
func _on_closed():
	print("Disconnected")
	connected = false
	emit_signal("server_disconnected")
		
func _on_error():
	client.disconnect_from_host()	
	
func _on_received():
	var packet = client.get_peer(1).get_packet()
	var dto = HexoidsProto.Dto.new();
	dto.from_bytes(packet)
	
	if (dto.has_events()):
		for event in dto.get_events().get_events():
			if event.has_boltExhausted():
				emit_signal("bolt_exhausted", event.get_boltExhausted(), dto)
			elif event.has_boltFired():
				emit_signal("bolt_fired", event.get_boltFired(), dto)
			elif event.has_playerFired():
				emit_signal("player_fired", event.get_playerFired(), dto)
			elif event.has_playerDestroyed():
				emit_signal("player_destroyed", event.get_playerDestroyed(), dto)
			elif event.has_playerJoined():
				emit_signal("player_joined", event.get_playerJoined(), dto)
			elif event.has_playerLeft():
				emit_signal("player_left", event.get_playerLeft(), dto)
			elif event.has_playerMoved():
				emit_signal("player_moved", event.get_playerMoved(), dto)
			elif event.has_playerSpawned():
				emit_signal("player_spawned", event.get_playerSpawned(), dto)
			elif event.has_playerScoreIncreased():
				emit_signal("player_score_increased", event.get_playerScoreIncreased(), dto)
			elif event.has_playerScoreUpdated():
				emit_signal("player_score_updated", event.get_playerScoreUpdated(), dto)
			elif event.has_scoreBoardUpdated():
				emit_signal("score_board_updated", event.get_scoreBoardUpdated(), dto)
	elif (dto.has_directedCommand()):
		var command = dto.get_directedCommand()
		if (command.has_playersList()):
			emit_signal("players_list_command", command.get_playersList(), dto)
		elif (command.has_playerScoreUpdate()):
			emit_signal("player_score_update_command", command.get_playerScoreUpdate(), dto)
		elif (command.has_liveBoltsList()):
			emit_signal("live_bolts_list_command", command.get_liveBoltsList(), dto)
	elif (dto.has_clock()):
		HClock.clock.onClockSync(joinTime ,dto.get_clock())
		
func sendMessage(message):
	if connected:
		client.get_peer(1).put_packet(message.to_bytes())

func _process(_delta):
	if client.get_connection_status() == WebSocketClient.CONNECTION_DISCONNECTED:
		return

	client.poll()
