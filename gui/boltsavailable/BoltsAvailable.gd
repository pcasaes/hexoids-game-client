extends VBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('current_view_command', self, '_on_current_view_command')
	Server.connect('bolts_available_command', self, '_on_bolts_available_command')
	PlayersStore.store.connect('player_created', self, '_player_created')

func _player_created(ship, _child):
	var style = $PanelContainer.get('custom_styles/panel');
	style.border_color = ship.color
	style.bg_color = ship.color
	style.bg_color.a = 0.25
	
	style = $PanelContainer/ProgressBar.get('custom_styles/fg');
	style.bg_color = ship.color
	
	
func _on_current_view_command(ev, _dto):
	$PanelContainer/ProgressBar.max_value = ev.get_boltsAvailable().get_available()

func _on_bolts_available_command(ev, _dto):
	$PanelContainer/ProgressBar.value = ev.get_available()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
