extends TileMap

# Note (IMPORTANT): World Origin is Top Left of Starting Screen - This May Change

# Non-Tilemap Generation - https://www.youtube.com/watch?v=skln7GPdB_A&list=PL0t9iz007UitFwiu33Vx4ZnjYQHH9th2r
# How Many Tilemaps - https://godotengine.org/qa/17780/create-multiple-small-tilemaps-or-just-a-giant
# 2D Tilemaps Chunk Theory - https://www.gamedev.net/forums/topic/653120-2d-tilemaps-chunk-theory/
# Intro Tilemap Procedural Generation (Reddit) - https://www.reddit.com/r/godot/comments/8v2xco/introduction_to_procedural_generation_with_godot/
# Into Tilemap Procedural Generation (Article) - https://steincodes.tumblr.com/post/175407913859/introduction-to-procedural-generation-with-godot
# Large Tilemap Generation - https://godotengine.org/qa/1121/how-go-about-generating-very-large-or-infinite-map-from-tiles
# Tilemap Docs - https://docs.godotengine.org/en/3.1/classes/class_tilemap.html

# World Gen Help
# Studying/Using This May Help - https://github.com/perdugames/SoftNoise-GDScript-
# Builtin Noise Generator - https://godotengine.org/article/simplex-noise-lands-godot-31
# OpenSimplexNoise - https://docs.godotengine.org/en/3.1/classes/class_opensimplexnoise.html

# Saving Data in Scene Files
# Answer to Question I Asked about Saving Variables to Scene - https://www.reddit.com/r/godot/comments/cp8siv/question_how_do_i_save_a_variable_to_a_scene_when/ewo070k/
# Custom Resources - https://github.com/godotengine/godot/issues/7037
# Save Custom Resource - https://godotengine.org/qa/8139/need-help-with-exporting-a-custom-ressource-type?show=8146#a8146
# Embed Resource into Scene - https://www.reddit.com/r/godot/comments/7xw6p9/is_there_any_way_to_embed_resource_into_a_scene/duh1bq0?utm_source=share&utm_medium=web2x
# Save Variables to Scene - https://www.patreon.com/posts/saving-godots-22268842
# Gist From Save Variables to Scene - https://gist.github.com/henriiquecampos/8d98f0660da499967d41c32988cd3612#gistcomment-2743040
# Explains About export(Resource) - https://godotengine.org/qa/8139/need-help-with-exporting-a-custom-ressource-type?show=14398#a14398

# Note: I am using a Tilemap to improve performance.
# This does mean world manipulation will be more complicated, but performance cannot be passed up.
# I am using SteinCode's Tumblr Article to help me get started.

# Declare member variables here. Examples:
var world_grid : Dictionary = {} # I use a dictionary so I can have negative coordinates.

# Tilemap uses ints to store tile ids. This means I do not have an infinite number of blocks.
# This will make things difficult if there are 100+ mods (all adding new blocks).
# Mojang used strings to solve this problem, but I don't know if I can make Tilemap use strings.
# I may have to create my own Tilemap from scratch (after release).
# Block IDs (referencing the Tilemap Tile ID)
const block : Dictionary = {
	'air': -1, # -1 means no tile exists - there is no such thing as block_air. It is just void.
	'stone': 0,
	'dirt': 1,
	'grass': 2
}

# Debug Tileset
var debug_tileset : TileSet = load("res://Objects/Blocks/Default-Debug.tres")

# Set's Worldgen size (Tilemap's Origin is Fixed to Same Spot as World Origin - I doubt I am changing this. Not unless changing it improves performance)
var quadrant_size : int = get_quadrant_size() # Default 16
var chunk_size : Vector2 = Vector2(quadrant_size, quadrant_size) # Tilemap is 32x32 (the size of a standard block) pixels per tile.
var world_size : Vector2 = Vector2(10, 10)

onready var world_node = self.get_owner() # Gets The Current World's Node
onready var background_tilemap : TileMap = get_node("Background") # Gets The Background Tilemap

export(String) var world_seed : String # World's Seed (used by generator to produce consistent results)
export(Array) var generated_chunks_foreground : Array # Store Generated Chunks IDs to Make Sure Not To Generate Them Again
export(Array) var generated_chunks_background : Array # Store Generated Chunks IDs to Make Sure Not To Generate Them Again

# TODO (IMPORTANT): Generate chunks array on world load instead of reading from file!!!
# Also, currently seeds aren't loaded from world handler, so they are generated new every time.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("World Generator Seed: ", world_seed)
	
	gamestate.debug_camera = true # Turns on Debug Camera - Useful for Debugging World Gen
	
	if gamestate.debug_camera:
		self.tile_set = debug_tileset
		background_tilemap.tile_set = debug_tileset
	
	background_tilemap.set_owner(world_node) # Set world as owner of Background Tilemap (allows saving Tilemap to world when client saves world)
	print("Background TileMap's Owner: ", background_tilemap.get_owner().name) # Debug Statement to list Background TileMap's Owner's Name
	
	# Seed should be set by world loader (if pre-existing world)
	if world_seed.empty():
		print("Generate Seed: ", generate_seed()) # Generates A Random Seed (Int) and Applies to Generator
		#print("Set Seed: ", set_seed("436123424")) # Converts Seed to Int and Applies to Generator
	
	for chunk_x in range(-world_size.x/2, world_size.x/2):
		for chunk_y in range(-world_size.y/2, world_size.y/2):
			#generate_foreground(chunk_x, chunk_y) # Generate The Foreground (Tiles Player Can Stand On and Collide With)
			generate_background(chunk_x, chunk_y) # Generate The Background (Tiles Player Can Pass Through)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float):
#	pass

func generate_foreground(chunk_x: int, chunk_y: int, regenerate: bool = false) -> void:
	"""
		Generate Tiles for Foreground Tilemap
		
		Dumps Tiles to World Grid
	"""
	
	if generated_chunks_foreground.has(Vector2(chunk_x, chunk_y)) and not regenerate:
		# Chunk already exists, do not generate it again.
		# I may add an override if someone wants to regenerate it later.
		
		# A different function will handle loading the world from save.
		return
		
	generated_chunks_foreground.append(Vector2(chunk_x, chunk_y))
	
	# The server could be handling multiple worlds at once (so, this makes sure the correct seed is loaded in the generator). This isn't my fault that the generator is global.
	set_seed(world_seed)
	
	world_grid.clear() # Empty World_Grid for New Data
	var noise = OpenSimplexNoise.new() # Create New SimplexNoise Generator
	
	# Get Chunk Generation Coordinates (allows finding where to spawn chunk)
	var horizontal : int = chunk_size.x + (quadrant_size * chunk_x)
	var vertical : int = chunk_size.y + (quadrant_size * chunk_y)
	
	# World Gen Code
	for coor_x in range((horizontal - quadrant_size), horizontal):
		# Configure Simplex Noise Generator (runs every x coordinate)
		noise.seed = randi()
		noise.octaves = 4
		noise.period = 20.0
		noise.lacunarity = 1.5
		noise.persistence = 0.8
		
		# Debug Chunk Location (places grass blocks at beginning of chunk)
		if coor_x % quadrant_size == 0:
			world_grid[coor_x] = {}
			world_grid[coor_x][vertical] = block.grass
			world_grid[coor_x][vertical - quadrant_size] = block.grass
			continue
		
		# How do I force this to be in the chunk? Should I force this to a chunk? I think yes.
		var noise_output : int = int(floor(noise.get_noise_2d(vertical, vertical + quadrant_size) * 5)) + 15
		#var noise_output : int = int(floor(noise.get_noise_2d((get_global_transform().origin.x + coor_x) * 0.1, 0) * vertical * 0.2)) - Modified From Non-Tilemap Generation Video (does not translate well :P)
		world_grid[coor_x] = {} # I set the Dictionary here because I may move away from the coor_x variable for custom worldgen types
		
		if noise_output < 0:
			world_grid[coor_x][noise_output] = block.grass
		else:
			world_grid[coor_x][noise_output] = block.dirt
		
		#print(noise_output)

	apply_foreground() # Apply World Grid to TileMap

# Generates The Background Tiles
func generate_background(chunk_x: int, chunk_y: int, regenerate: bool = false):
	"""
		Generate Tiles for Background Tilemap
		
		Dumps Tiles to World Grid
	"""
	
	if generated_chunks_background.has(Vector2(chunk_x, chunk_y)) and not regenerate:
		# Chunk already exists, do not generate it again.
		# I may add an override if someone wants to regenerate it later.
		
		# A different function will handle loading the world from save.
		return
		
	generated_chunks_background.append(Vector2(chunk_x, chunk_y))
	
	# The server could be handling multiple worlds at once (so, this makes sure the correct seed is loaded in the generator). This isn't my fault that the generator is global.
	set_seed(world_seed)
	
	world_grid.clear() # Empty World_Grid for New Data
	
	# Get Chunk Generation Coordinates (allows finding where to spawn chunk)
	var horizontal : int = chunk_size.x + (quadrant_size * chunk_x)
	var vertical : int = chunk_size.y + (quadrant_size * chunk_y)

	# NOTE (Important): This is for testing the chunk selection process
	var random_block : int = randi() % (block.size() - 1)

	# World Gen Code
	for coor_x in range((horizontal - quadrant_size), horizontal):
		world_grid[coor_x] = {}

		for coor_y in range((vertical - quadrant_size), vertical):
			world_grid[coor_x][coor_y] = random_block

	apply_background() # Apply World Grid to TileMap

func apply_foreground() -> void:
	"""
		Applies World Grid to Foreground TileMap
		
		Not Meant To Be Called Directly
	"""
	
	# Set's Tile ID in Tilemap from World Grid
	for coor_x in world_grid.keys():
		for coor_y in world_grid[coor_x].keys():
			#print("Coordinate: (", coor_x, ", ", coor_y, ") - Value: ", world_grid[coor_x][coor_y])
			set_cell(coor_x, coor_y, world_grid[coor_x][coor_y])

func apply_background() -> void:
	"""
		Applies World Grid to Background TileMap
		
		Not Meant To Be Called Directly
	"""
	
	# Z-Index for Background is -1 (Foreground is 0).
	# This Makes Foreground Cover Up Background
	
	# Set's Tile ID in Tilemap from World Grid
	for coor_x in world_grid.keys():
		for coor_y in world_grid[coor_x].keys():
			#print("Coordinate: (", coor_x, ", ", coor_y, ") - Value: ", world_grid[coor_x][coor_y])
			background_tilemap.set_cell(coor_x, coor_y, world_grid[coor_x][coor_y])

func generate_seed() -> int:
	"""
		Generates a Seed and Set as World's Seed
	"""
	
	randomize() # This is void, and I cannot get the seed directly, so I have to improvise.
	var random_seed : int = randi() # Generate a random int to use as a seed
	
	world_seed = str(random_seed)
	seed(random_seed) # Activate Random Generator With Seed
	
	return random_seed # Returns seed for saving for player and inputting into generator later

func set_seed(random_seed: String) -> int:
	"""
		Sets World's Seed
	"""
	
	world_seed = random_seed
	
	# If Not A Pure Integer (in String form), then Hash String To Integer
	if not world_seed.is_valid_integer():
		seed(world_seed.hash()) # Activate Random Generator With Seed
		return world_seed.hash()
		
	# If Pure Integer (in String form), then convert to Integer Type
	seed(int(world_seed)) # Activate Random Generator With Seed
	return int(world_seed)
