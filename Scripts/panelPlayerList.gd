extends Panel

# Called when the node enters the scene tree for the first time.
func _ready():
	player_registrar.connect("player_list_changed", self, "_on_player_list_changed") # Register When Player List Has Been Changed
	get_tree().get_root().get_node("PlayerUI").connect("cleanup_ui", self, "cleanup") # Register With PlayerUI Cleanup Signal - Useful for Modders
	
# Load Player List - Called When Player Joins Server
func loadPlayerList():
	#print("Player List")

	# Do Not Run Below Code if Headless
	var localPlayer = $lblLocalPlayer
	localPlayer.text = gamestate.player_info.name # Display Local Client's Text on Screen
	localPlayer.align = Label.ALIGN_CENTER # Aligns the Text To Center
	localPlayer.add_font_override("font", load("res://Fonts/dynamicfont/firacode-regular.tres")) # TODO: Fonts will be able to be chosen by player (including custom fonts added by player)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# Update Player List in GUI
func _on_player_list_changed():
	# TODO: Replace the player list with a rich text label to implement clicking on player names (and add player icons (profile pics?))
	
	#print("Player List Changed!!!")
	
	# Remove Nodes From Boxlist
	for node in $boxList.get_children():
		node.queue_free()
	
	# Populate Boxlist With Player Names
	for player in player_registrar.players:
		if (player != gamestate.net_id):
			var connectedPlayerLabel = Label.new()
			connectedPlayerLabel.align = Label.ALIGN_CENTER # Aligns the Text To Center
			connectedPlayerLabel.text = player_registrar.players[int(player)].name
			connectedPlayerLabel.add_font_override("font", load("res://Fonts/dynamicfont/firacode-regular.tres")) # TODO: Fonts will be able to be chosen by player (including custom fonts added by player)
			$boxList.add_child(connectedPlayerLabel)
			
# Cleanup PlayerList - Meant to be Called by PlayerUI
func cleanup():
	# Remove Nodes From Boxlist
	for node in $boxList.get_children():
		node.queue_free()