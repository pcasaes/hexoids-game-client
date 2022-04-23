extends VBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var log_base_10 = log(10)


# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('current_view_command', self, '_on_current_view_command')
	Server.connect('bolts_available_command', self, '_on_bolts_available_command')
	Server.connect('player_moved', self, '_on_player_moved')
	PlayersStore.store.connect('player_created', self, '_player_created')

func _player_created(ship, _child, isUser):
	if isUser:
		var style = $boltsAvailable.get('custom_styles/panel');
		style.border_color = ship.color
		style.bg_color = ship.color
		style.bg_color.a = 0.25
		
		style = $inertialDampen.get('custom_styles/panel');
		style.border_color = ship.color
		style.bg_color = ship.color
		style.bg_color.a = 0.25
		
		style = $boltsAvailable/progress.get('custom_styles/fg');
		style.bg_color = ship.color
		
		style = $inertialDampen/progress.get('custom_styles/fg');
		style.bg_color = ship.color
		$inertialDampen/progress.max_value = 6
		$inertialDampen/progress.value = 6
		$inertialDampen/progress.step = 0.001
		visible = true

func _on_player_moved(ev, _dto):
	var guid = ev.get_playerId().get_guid()
	if User.is_user_from_guid(guid):
		var factor = ev.get_inertialDampenFactor()
		$inertialDampen/progress.value = min(6, max(0, (log(factor)/log_base_10) + 6))
	
func _on_current_view_command(ev, _dto):
	$boltsAvailable/progress.max_value = ev.get_boltsAvailable().get_available()

func _on_bolts_available_command(ev, _dto):
	$boltsAvailable/progress.value = ev.get_available()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
