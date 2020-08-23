extends CenterContainer

const HexoidsProto = preload("res://server/HexoidsProto.gd")


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var store = GUIStore.store

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('player_spawned', self, '_on_player_spawned')
	Server.connect('player_destroyed', self, '_on_player_destroyed')

func _on_player_spawned(ev, _dto):
	if store.getMyPlayerId() == ev.get_location().get_playerId().get_guid():
		self.visible = false
		
func _on_player_destroyed(ev, _dto):
	if store.getMyPlayerId() == ev.get_playerId().get_guid():
		var p = store.get(store.getMyPlayerId())
		if p != null:
			$Label.set("custom_colors/font_color", p.color)			
		self.visible = true
	
func _input(event):
	if self.visible and event.is_action_pressed("ui_respawn"):
		var request = HexoidsProto.RequestCommand.new()
		request.new_spawn()		
		
		Server.sendMessage(request)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
