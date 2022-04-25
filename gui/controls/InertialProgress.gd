extends PanelContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


var log_base_10 = log(10)

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('player_moved', self, '_on_player_moved')
	PlayersStore.store.connect('player_created', self, '_player_created')

func _player_created(ship, _child, isUser):
	if isUser:
		
		$progress.tint_under = ship.color
		$progress.tint_under.a = 0.125
		$progress.tint_progress = ship.color
		
		$progress.max_value = 6
		$progress.value = 6
		$progress.step = 0.001
		visible = true

func _on_player_moved(ev, _dto):
	var guid = ev.get_playerId().get_guid()
	if User.is_user_from_guid(guid):
		var factor = ev.get_inertialDampenFactor()
		$progress.value = min(6, max(0, (log(factor)/log_base_10) + 6))

