extends Node

const HexoidsProto = preload("res://server/HexoidsProto.gd")
const CONFIG_FILE = "user://server.cfg"
const CLIENT_VERSION = '0.4.1'

signal server_disconnected
signal server_connected
signal server_connecting

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
signal current_view_command
signal player_score_update_command
signal live_bolts_list_command
signal bolts_available_command

# client check
signal checking_client
signal client_check_failed
signal client_supported
signal client_version

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


var client
var connected = false;
var joinTime

var _config

var _HOST = 'ws://hexoids.duckdns.org:28080'

var host setget set_host, get_host

var clientVersion = Classes.SymVer.new(CLIENT_VERSION)
var expectedClientVersion

var clientsAvailableRequest

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Client platform: " + OS.get_name())
	_config = ConfigFile.new()
	
	if can_change_host():
		var err = _config.load(CONFIG_FILE)
		if err == OK:
			host = _config.get_value("server", "host", _HOST)
		else:
			host = _HOST
			_config.set_value("server", "host", host)
			_config.save(CONFIG_FILE)
	else:
		var location_host = JavaScript.eval("location.host", true)
		var location_protocol = JavaScript.eval("location.protocol", true)
		_HOST = 'ws'
		if location_protocol.to_lower() == 'https:':
			_HOST = _HOST + 's'
		_HOST = _HOST + '://' + location_host
			
		host = _HOST
		
	clientsAvailableRequest = HTTPRequest.new()
	add_child(clientsAvailableRequest)
	clientsAvailableRequest.connect("request_completed", self, "_on_client_available_request_completed")
	
func open_download_page():
	if expectedClientVersion == null:
		OS.shell_open('https://github.com/pcasaes/hexoids-game-client/releases')
	else:
		OS.shell_open('https://github.com/pcasaes/hexoids-game-client/releases/tag/'+expectedClientVersion)
		
func reset_host():
	if can_change_host():
		request_clients_available(_HOST)
	
func can_change_host():
	return OS.get_name() != 'HTML5' or JavaScript.eval('location.host', true).find('localhost') == 0
		
func set_host(h):
	if h != host:
		host = h
		_config.set_value("server", "host", host)
		_config.save(CONFIG_FILE)
	
func get_host():
	return host
	
func request_clients_available(h = null):
	if h != null:
		set_host(h)
	
	var req = 'http' + host.substr(2) + '/clients/available'
	print("Requesting clients available from: " + req)
	emit_signal('checking_client')
	clientsAvailableRequest.request(req)
		

func _on_client_available_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8())
		print(json.result)
		expectedClientVersion = json.result[OS.get_name()]
		emit_signal("client_version", expectedClientVersion)
		var ver = Classes.SymVer.new(expectedClientVersion)
		if clientVersion.greaterThanOrEqualTo(ver):
			print("client version ok")
			emit_signal('client_supported', true)
		else:
			print("client version old")
			emit_signal('client_supported', false)
	else:
		print("Response code: " + str(response_code))
		if body != null:
			print("Body: " + body.get_string_from_utf8())
		else:
			print("No body")
		emit_signal('client_check_failed')
			

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
	emit_signal("server_connecting")
	print("Starting server for user " + User.id)
	var endpoint = host + '/game/' + User.id
	var err = client.connect_to_url(endpoint)
	print("Connection status: " + str(err))
	
func _on_opened(_protocol):
	client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_BINARY)
	connected = true
	print("connected to host")
	joinTime = HClock.clock.clientTime()
	var request = HexoidsProto.RequestCommand.new()
	
	var cp = OS.get_name().to_upper()
	var clientPlatform = HexoidsProto.ClientPlatforms.UNKNOWN
	
	for k in HexoidsProto.ClientPlatforms.keys():
		if k == cp:
			clientPlatform = HexoidsProto.ClientPlatforms[k]
			break

	print("Client Platform: " + HexoidsProto.ClientPlatforms.keys()[clientPlatform])
	var joinCommand = request.new_join()
	joinCommand.set_name(User.username)
	joinCommand.set_clientPlatform(clientPlatform)
	
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
				if User.is_user_from_guid(event.get_playerLeft().get_playerId().get_guid()):
					client.disconnect_from_host()
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
		if (command.has_boltsAvailable()):
			emit_signal("bolts_available_command", command.get_boltsAvailable(), dto)
		elif (command.has_playerScoreUpdate()):
			emit_signal("player_score_update_command", command.get_playerScoreUpdate(), dto)
		elif (command.has_currentView()):
			emit_signal("current_view_command", command.get_currentView(), dto)
			emit_signal("bolts_available_command", command.get_currentView().get_boltsAvailable(), dto)
		elif (command.has_liveBoltsList()):
			emit_signal("live_bolts_list_command", command.get_liveBoltsList(), dto)
	elif (dto.has_clock()):
		HClock.clock.onClockSync(joinTime ,dto.get_clock())
		
func sendMessage(message):
	if connected:
		client.get_peer(1).put_packet(message.to_bytes())

func _physics_process(_delta):
	if client.get_connection_status() == WebSocketClient.CONNECTION_DISCONNECTED:
		return

	client.poll()
