extends VBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var store = GUIStore.store


const MAX = 10 
const MIN_REFRESH_IN_SECONDS = 0.5

var DISTANCE_X = HexoidsConfig.world.xToModel(1000)
var DISTANCE_Y = HexoidsConfig.world.yToModel(1000)
var placement = {}
var refresh_delta = 0

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
		label.visible = false
		add_child(label)

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
	refresh_delta = refresh_delta + _delta
	if refresh_delta > MIN_REFRESH_IN_SECONDS:
		var myPlacement = placement.get(store.getMyPlayerId())
		var shownLabels = 0
		if myPlacement != null:	
			for k in placement.keys():
				if k != User.getId():
					var pos = placement[k]
					if abs(myPlacement.get_x() - pos.get_x()) < DISTANCE_X and abs(myPlacement.get_y() - pos.get_y()) < DISTANCE_Y:
						var player = store.get(k)
						var label = get_child(shownLabels)
						if player != null:
							label.text = player.displayName
							label.set("custom_colors/font_color", player.color)
						else:
							label.text = k.substr(0, HexoidsConfig.world.hud.nameLength)
							label.set("custom_colors/font_color", HexoidsColors.getDarkTextColor().color)
							
						label.visible = true
						shownLabels = shownLabels + 1
						if (shownLabels == MAX):
							break
		
		for i in range(shownLabels, MAX):
			get_child(i).visible = false
			
		refresh_delta = 0
		
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
