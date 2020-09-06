extends CenterContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var _current = Screen.LOADING
var _fade = false
var _next = null

var _from
var _to

var _wait_to_start_time = 0
var done_waiting = false

var _connected = false
var _connected_wait = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect("server_connecting", self, '_on_server_connecting')
	Server.connect("client_supported", self, '_on_client_supported')
	Server.connect("client_check_failed", self, '_on_client_check_failed')
	Server.connect("checking_client", self, '_on_server_connecting')
	Server.connect('player_moved', self, '_on_player_action')
	Server.connect('player_destroyed', self, '_on_player_action')
	
func _on_player_action(ev, _dto):
	var guid = ev.get_playerId().get_guid()
	if guid == User.id:
		_connected = true

func _on_client_supported(v):
	if v:
		_show(Screen.START)
	else:
		_show(Screen.CHECK_CLIENT)

func _on_server_connecting():
	_show(Screen.LOADING)

func _on_client_check_failed():
	_show(Screen.CLIENT_CHECK_FAILED)

func _show(v):
	if _current != v:
		if _fade:
			_next = v
		else:
			_next = null
			_from = get_child(_current)
			_to = get_child(v)
			
			if _to == $Loading:
				_to.modulate.a = 1
			else:
				_to.modulate.a = 0
			_to.visible = true
			_fade = true
			_current = v
			
			if _from == $Loading:
				_from.modulate.a = 0
				_from.visible = false
			else:
				$TransitionSound.play()

func _physics_process(delta):
	if _connected:
		_connected_wait = _connected_wait + delta
		if _connected_wait > 0.3:
			$Loading.fade_out()
			modulate.a = max(0,modulate.a - delta)
			if modulate.a == 0:
				self.visible = false
				queue_free()
			
		
	if not done_waiting:
		_wait_to_start_time = _wait_to_start_time + delta
		if _wait_to_start_time > 2:
			Server.request_clients_available()
			done_waiting = true
		
	if _fade:
		if _from.modulate.a > 0:
			_from.modulate.a = max(0,_from.modulate.a - delta)
			_from.modulate.a = max(0,_from.modulate.a - delta)
		else:
			_to.modulate.a = min(1,_to.modulate.a + delta)
			_to.modulate.a = min(1,_to.modulate.a + delta)
		if _to.modulate.a == 1 and _from.modulate.a == 0:
			_from.visible = false
			_fade = false
			if _next != null:
				_show(_next)
		
enum Screen {
	LOADING=0
	START=1
	CHECK_CLIENT	=2
	CLIENT_CHECK_FAILED=3
}
