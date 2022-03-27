extends VBoxContainer

const HexoidsProto = preload("res://server/HexoidsProto.gd")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var store = GUIStore.store


const MAX = 10 

var DISTANCE_X = HexoidsConfig.world.xToModel(1000)
var DISTANCE_Y = HexoidsConfig.world.yToModel(1000)
var placement = {}
var my_players_moved_event

# Called when the node enters the scene tree for the first time.
func _ready():
	my_players_moved_event = HexoidsProto.PlayerMovedEventDto.new()
	my_players_moved_event.set_x(-999999)
	my_players_moved_event.set_y(-999999)
	_on_resize()
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

func _on_resize():
	DISTANCE_X = HexoidsConfig.world.xToModel(get_viewport_rect().size.x+128)
	DISTANCE_Y = HexoidsConfig.world.yToModel(get_viewport_rect().size.y+128)
	print("Nearby Limit X ", DISTANCE_X)
	print("Nearby Limit Y ", DISTANCE_Y)


func _on_server_disconnected():
	placement.clear()
	for label in get_children():
		label.visible = false

func _on_player_moved(ev, _dto):
	_moved(ev)
	
func _on_player_spawned(ev, _dto):
	_moved(ev.get_location())
			
func _on_player_destroyed_or_left(ev, _dto):
	var label = placement.get(ev.get_playerId().get_guid())
	if is_instance_valid(label):
		label.visible = false
		placement.erase(ev.get_playerId().get_guid())

func _in_view(ev):
	var xd = abs(my_players_moved_event.get_x() - ev.get_x())
	var yd = abs(my_players_moved_event.get_y() - ev.get_y())
	
	if xd < DISTANCE_X and yd < DISTANCE_Y:
		return 1.0 - min(xd / DISTANCE_X, yd / DISTANCE_X)
	return null
	
func _moved(ev):
	var playerId = ev.get_playerId().get_guid()
	if User.is_user_from_guid(playerId):
		my_players_moved_event = ev
	else:
		var d = _in_view(ev)
		if d != null:
			var l = placement.get(playerId);
			if !is_instance_valid(l):
				for label in get_children():
					if !label.visible:
						var player = store.get(playerId)
						if player != null:
							label.text = player.displayName
							label.set("custom_colors/font_color", player.color)
						else:
							label.text = HexoidsConfig.world.hud.get_temp_name(playerId)
							label.set("custom_colors/font_color", HexoidsColors.getDarkTextColor().color)
							
						label.visible = true
						placement[playerId] = label
						label.modulate.a = d
						break
			else:
				l.modulate.a = d
		else:
			var label = placement.get(playerId)
			if is_instance_valid(label):
				label.visible = false
				placement.erase(playerId)
				
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
