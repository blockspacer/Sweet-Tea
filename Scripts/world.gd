extends Node2D

# panelPlayerStats is meant for information like health and a hotbar

# Declare member variables here. Examples:
onready var playerList = $PlayerUI/panelPlayerList

# Main Function - Registers Event Handling (Handled By Both Client And Server)
func _ready():
	network.connect("player_list_changed", self, "_on_player_list_changed")
	
	# Do Not Run Below Code if Headless
	var localPlayer = $PlayerUI/panelPlayerList/lblLocalPlayer
	localPlayer.text = gamestate.player_info.name # Display Local Client's Text on Screen
	localPlayer.align = Label.ALIGN_CENTER # Aligns the Text To Center
	localPlayer.add_font_override("font", load("res://Fonts/dynamicfont/firacode-regular.tres")) # Fonts will be able to be chosen by player (including custom fonts added by player)

	if (get_tree().is_network_server()):
		network.connect("player_removed", self, "_on_player_removed") # Register Player Removal Function
		
		# TODO: Make Sure Not To Execute this line of spawn_player_server(...) if Running Headless
		spawn_players_server(gamestate.player_info) # Spawn Players (Currently Only Server's Player)
	else:
		rpc_id(1, "spawn_players_server", gamestate.player_info) # Request for Server To Spawn Player

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	# This allows user to see player list (I will eventually add support to change keys and maybe joystick support)
	if Input.is_key_pressed(KEY_TAB):
		playerList.visible = true
	else:
		playerList.visible = false

# For the server only
master func spawn_players_server(pinfo):
	var coordinates = Vector2(300, 300) # Get rid of all references to this
	
	if (get_tree().is_network_server() && pinfo.net_id != 1):
		# We Are The Server and The New Player is Not The Server
		
		# TODO: Validate That Player ID is Not Spoofed
		# Apparently the RPC ID (used as Player ID) is safe from spoofing? I need to do more research just to be sure.
		# https://www.reddit.com/r/godot/comments/bf4z8r/is_get_rpc_sender_id_safe_enough/eld38y8?utm_source=share&utm_medium=web2x
		
		for id in network.players:
			# Spawn Existing Players for New Client (Not New Player)
			# All clients' coordinates (including server's coordinates) get sent to new client (except for the new client)
			if (id != pinfo.net_id):
				var player = get_node(str(id) + "/KinematicBody2D") # Grab Existing Player's Object (Server Only)
				print("Existing: ", id, " For: ", pinfo.net_id, " At Coordinates: ", player.position) # player.position grabs existing player's coordinates
				# --------------------------Get rid of coordinates from the function arguments and retrieve coordinates from dictionary)--------------------------
				# Separate Coordinate Variable From Rest of Function
				rpc_id(pinfo.net_id, "spawn_players", network.players[id], player.position) # TODO: This line of code is at fault for the current bug
				
			# Spawn the new player within the currently iterated player as long it's not the server
			# Because the server's list already contains the new player, that one will also get itself!
			# New Player's Coordinates gets sent to all clients (including new player/client) except the server
			if (id != 1):
				print("New: ", id, " For: ", pinfo.net_id, " At Coordinates: ", coordinates)
				# Same here, get from dictionary, keep separate
				rpc_id(id, "spawn_players", pinfo, coordinates)
				
	add_player(pinfo, coordinates)

# Spawns a new player actor, using the provided player_info structure and the given spawn index
# http://kehomsforge.com/tutorials/multi/gdMultiplayerSetup/part03/ - "Spawning A Player"
# TODO (IMPORTANT): Let server decide coordinates and not client
# For client only
remote func spawn_players(pinfo, coordinates: Vector2):
	#global_position = pinfo
	
	print("Spawning Player: ", pinfo.net_id, " At Coordinates: ", coordinates)
	
	if (get_tree().is_network_server() && pinfo.net_id != 1):
		# TODO: Validate That Player ID is Not Spoofed
		# We Are The Server and The New Player is Not The Server
		
		for id in network.players:
			# Spawn Existing Players for New Client (Not New Player)
			# All clients' coordinates (including server's coordinates) get sent to new client (except for the new client)
			if (id != pinfo.net_id):
				print("Existing: ", id, " For: ", pinfo.net_id, " At Coordinates: ", coordinates)
				# --------------------------Get rid of coordinates from the function arguments and retrieve coordinates from dictionary)--------------------------
				# Separate Coordinate Variable From Rest of Function
				rpc_id(pinfo.net_id, "spawn_players", network.players[id], coordinates) # TODO: This line of code is at fault for the current bug
				
			# Spawn the new player within the currently iterated player as long it's not the server
			# Because the server's list already contains the new player, that one will also get itself!
			# New Player's Coordinates gets sent to all clients (including new player/client) except the server
			if (id != 1):
				print("New: ", id, " For: ", pinfo.net_id)
				# Same here, get from dictionary, keep separate
				rpc_id(id, "spawn_players", pinfo, coordinates)
	
	add_player(pinfo, coordinates)
	
func add_player(pinfo, coordinates: Vector2):
	# Load the scene and create an instance
	var player_class = load(pinfo.actor_path)
	var new_actor = player_class.instance()
	
	# TODO: Make Sure Alpha is 255 (fully opaque). We don't want people cheating...
	# Setup Player Customization
	new_actor.get_node("KinematicBody2D").set_dominant_color(pinfo.char_color) # The player script is attached to KinematicBody2D, hence retrieving its node
	
	print("Actor: ", pinfo.net_id)
	new_actor.get_node("KinematicBody2D").position = coordinates # Setup Player's Position
	
	new_actor.set_name(str(pinfo.net_id)) # Set Player's ID (useful for referencing the player object later)
	
	# Hand off control to player's client (the server already controls itself)
	if (pinfo.net_id != 1):
		new_actor.set_network_master(pinfo.net_id)
		
	# Add the player to the world
	add_child(new_actor)

# Server and Client - Despawn Player From Local World
remote func despawn_player(pinfo):
	# TODO: Fix Error Mentioned at: http://kehomsforge.com/tutorials/multi/gdMultiplayerSetup/part03/. The error does not break the game at all, it just spams the console.
	# "ERROR: _process_get_node: Invalid packet received. Unabled to find requested cached node. At: core/io/multiplayer_api.cpp:259."
	
	if (get_tree().is_network_server()):
		for id in network.players:
			# Skip sending the despawn packet to both the disconnected player and the server (itself)
			if (id == pinfo.net_id || id == 1):
				continue
			
			# Notify players (clients) of despawned player
			rpc_id(id, "despawn_player", pinfo)
	
	# Locate Player To Despawn
	var player_node = get_node(str(pinfo.net_id))
	
	if (!player_node):
		print("Failed To Find Player To Despawn")
		return
	
	# Despawn Player from World
	player_node.queue_free()
	
# Server Only - Call the Despawn Player Function
func _on_player_removed(pinfo):
	despawn_player(pinfo)

# Update Player List in GUI
func _on_player_list_changed():
	# Remove Nodes From Boxlist
	for node in $PlayerUI/panelPlayerList/boxList.get_children():
		node.queue_free()
	
	# Populate Boxlist With Player Names
	for player in network.players:
		if (player != gamestate.player_info.net_id):
			var connectedPlayerLabel = Label.new()
			connectedPlayerLabel.align = Label.ALIGN_CENTER # Aligns the Text To Center
			connectedPlayerLabel.text = network.players[player].name
			connectedPlayerLabel.add_font_override("font", load("res://Fonts/dynamicfont/firacode-regular.tres"))
			$PlayerUI/panelPlayerList/boxList.add_child(connectedPlayerLabel)