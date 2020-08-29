extends SoundHandler


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const explosion_res = preload("res://sounds/samples/explosion_res.tscn")

var playerStore = PlayersStore.store

# Called when the node enters the scene tree for the first time.
func _ready():
	type = explosion_res
	playerStore.connect('ship_destroyed', self, '_ship_destroyed')
	
func _ship_destroyed(destroyerId, ship):
		var priority = ship.is_players_ship() or destroyerId == User.getId()	
		play_in_view(priority, ship.position.x, ship.position.y)
	
