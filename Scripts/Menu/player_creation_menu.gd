extends Control

signal character_created # Signal to Let Other Popup Know When Character Has Been Created

# Declare member variables here. Examples:
var old_title : String = "" # Title From Before Window Was Shown
var slot : int # Save Slot to Use For Character
var is_client : bool = false # Determine If Is Server or Client
var world_seed : String # Seed to use to generate world

# Called when the node enters the scene tree for the first time.
func _ready():
	#$PlayerCreationWindow.window_title = "Hello" # Can be used for translation code
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func create_character() -> void:
	logger.info("Slot: %s" % slot)
	
	gamestate.player_info.char_color = "ff000000"
	gamestate.player_info.char_unique_id = gamestate.generate_character_unique_id()
	gamestate.player_info.debug = false
	gamestate.player_info.name = "Default Name"
	
	# This is setup so worldgen does not happen if the new character was created for the purpose of joining a server.
	# This will help save processing time as worldgen can be delayed until later
	if is_client:
		gamestate.player_info.world_created = false
		gamestate.player_info.world_seed = world_seed
		gamestate.player_info.starting_world = "Not Set" # Fixes A Bug Where World Path Can Appear to Be Set, but Isn't
		gamestate.save_player(slot)
	else:
		create_world()
		gamestate.save_player(slot)
		network.start_server()
	
	$PlayerCreationWindow.hide() # Hides Own Popup Menu
	emit_signal("character_created") # Alerts Player Selection Menu That It Can Continue Processing The Scene To Load (If Any)

# This is a function as I need to call this in player selection without resetting the character's variables
func create_world() -> void:
	var world_name = world_handler.create_world(-1, world_seed, Vector2(0, 0)) # The Vector (0, 0) is here until I decide if I want to generate a custom world size. This will just default to what the generator has preset.
		
	gamestate.player_info.starting_world = "user://worlds/".plus_file(world_name)
	
	#gamestate.save_player(slot)

	logger.verbose("Player Creation Menu - Starting Server (Singleplayer)")
	world_handler.save_world(world_handler.get_world(world_name))

func set_seed(set_seed: String) -> void:
	world_seed = set_seed

func set_slot(character_slot: int) -> void:
	slot = character_slot
	logger.verbose("Selecting Slot %s for Creating Character" % character_slot)

func set_client(client: bool = true) -> void:
	is_client = client

func _about_to_show() -> void:
	old_title = functions.get_title()
	functions.set_title(tr("Create_Character_Title"))

func _about_to_hide() -> void:
	"""
		Reset Title to Before
		
		Not Meant to Be Called Directly
	"""
	
	functions.set_title(old_title)
