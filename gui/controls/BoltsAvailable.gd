extends PanelContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('current_view_command', self, '_on_current_view_command')
	Server.connect('bolts_available_command', self, '_on_bolts_available_command')
	PlayersStore.store.connect('player_created', self, '_player_created')


func _player_created(ship, _child, isUser):
	if isUser:
		
		$progress.tint_under = ship.color
		$progress.tint_under.a = 0.125
		$progress.tint_progress = ship.color
		
		visible = true
	
func _on_current_view_command(ev, _dto):
	$progress.max_value = ev.get_boltsAvailable().get_available()

func _on_bolts_available_command(ev, _dto):
	$progress.value = ev.get_available()
