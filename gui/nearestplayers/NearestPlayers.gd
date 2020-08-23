extends VBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var store = GUIStore.store


const MAX = 10 
var DISTANCE_X = HexoidsConfig.world.xToModel(1000)
var DISTANCE_Y = HexoidsConfig.world.yToModel(1000)
var placement = {}
var labelsPool = []

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('player_spawned', self, '_on_player_spawned')
	Server.connect('player_moved', self, '_on_player_moved')
	Server.connect('player_left', self, '_on_player_destroyed_or_left')
	Server.connect('player_destroyed', self, '_on_player_destroyed_or_left')
	Server.connect('server_disconnected', self, '_on_server_disconnected')
	for _i in range(MAX):
		var label = Label.new()
		label.align = 2
		labelsPool.push_back(label)

func _on_server_disconnected():
	placement.clear()
	
func _on_player_moved(ev, _dto):
	if (placement.get(ev.get_playerId().get_guid()) != null):
		placement[ev.get_playerId().get_guid()] = ev
	
func _on_player_spawned(ev, _dto):
	placement[ev.get_location().get_playerId().get_guid()] = ev.get_location()
			
func _on_player_destroyed_or_left(ev, _dto):
	placement.erase	(ev.get_playerId().get_guid())
	
func _physics_process(_delta):
	while get_child_count() > 0:
		remove_child(get_child(0))

	var myPlacement = placement.get(store.getMyPlayerId())
	if myPlacement != null:	
		var pool_index = 0	
		for k in placement.keys():
			if k != store.getMyPlayerId():
				var pos = placement[k]
				if abs(myPlacement.get_x() - pos.get_x()) < DISTANCE_X and abs(myPlacement.get_y() - pos.get_y()) < DISTANCE_Y:
					var player = store.get(k)
					var label = labelsPool[pool_index]
					if player != null:
						label.text = player.displayName
						label.set("custom_colors/font_color", player.color)
					else:
						label.text = k.substr(0, HexoidsConfig.world.hud.nameLength)
						label.set("custom_colors/font_color", HexoidsColors.getDarkTextColor().color)
					add_child(label)
					pool_index = pool_index + 1
					if (pool_index == MAX):
						break

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
