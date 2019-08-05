extends Control

# Interesting Links
# https://docs.godotengine.org/en/3.1/getting_started/step_by_step/scripting_continued.html#overrideable-functions
# https://docs.godotengine.org/en/latest/classes/class_projectsettings.html

# Performance Improving Links
# https://docs.godotengine.org/en/3.1/classes/class_engine.html#class-engine-property-iterations-per-second
# https://godotengine.org/article/why-does-godot-use-servers-and-rids - About Multi-Cores and Threading
# https://docs.godotengine.org/en/3.1/tutorials/threads/using_multiple_threads.html - Multithreading

# Quick Read
# https://github.com/godotengine/godot/issues/7832

# This is to test a custom module I compiled Godot with for encryption that I can use with RPC.
# More on this later.
# TODO: Add MBedTLS and Cripte to License Docs

# 3.2.dev export template download (2 files needed) - https://hugo.pro/projects/godot-builds/
# Actually, you need to compile the export template (because of custom modules)
# http://docs.godotengine.org/en/stable/development/compiling/compiling_for_windows.html#creating-windows-export-templates
# https://docs.godotengine.org/en/3.1/development/compiling/compiling_for_x11.html#building-export-templates
# OSX does not have explicit instructions on how to compile export templates - http://docs.godotengine.org/en/stable/development/compiling/compiling_for_osx.html

# Since I Use Mac, I Am Leaving A Link About Cross Compiling Godot
# http://docs.godotengine.org/en/stable/development/compiling/compiling_for_windows.html#cross-compiling-for-windows-from-other-operating-systems
# It appears I cannot cross compile for Linux from Mac, so I will have to install a Linux VM when I get close to releasing the game

# I am currently compiling for OSX with the command: scons platform=osx tools=no target=release bits=64
# Lets Hope it Works
func test_module():
	var Cripte = cripter.new()

	var key = "My not secret key"

	var gcm_add = "adicional data is: port: 316"
	var gcm_input = var2bytes("The cow goes muuuu")

	var encrypted_array_gcm = Cripte.encrypt_byte_GCM(gcm_input, key, gcm_add)
	var decrypted_array_gcm = Cripte.decrypt_byte_GCM(encrypted_array_gcm, key, gcm_add) 

	print("Encrypted: ", encrypted_array_gcm.get_string_from_ascii())
	print("Decrypted: ", bytes2var(decrypted_array_gcm))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Sets Window's Title
	OS.set_window_title("This is a Title")
	
	test_module()
	
	# Supposed to Request Window Attention - Probably Only Works if Window is Out of Focus
	#OS.request_attention()
	
	# If not careful, the game can easily make a laptop hot. For computers that can handle processing as quickly as possible, this can be disabled.
	# TODO: Provide option in settings to turn this off.
	#OS.low_processor_usage_mode = true # Default Off - Meant for programs (as not in games - Causes performance issues in game)
	OS.vsync_enabled = true # Already enabled by default, but can be changed by code.
	
	# This doesn't do anything, but if I could find a way to change these settings in gdscript, I could help make the gamw work on lower end computers.
	Engine.set_iterations_per_second(30) # Physics FPS - Default 60
	Engine.set_target_fps(30) # Rendering FPS - Default Unlimited
	#ProjectSettings.save()
	
	print("Number of Cores: ", OS.get_processor_count())
	print("Multithread Support: ", OS.can_use_threads())
	
	if OS.can_use_threads():
		# Figure out how to change Rendering Thread Model in GDScript
		pass
	
	# https://godotengine.org/qa/11251/how-to-export-the-project-for-server?show=11253#a11253
	# Checks if Running on Headless Server (Currently Linux Only? There is a commit where someone added support for OSX, but no official builds)
	# I compiled Godot's Server Executable and it cannot run the server without the original source code. This could cause problems for execution speed when the binaries are not precompiled.
	# Also, OS.get_unique_id(), does not work in my Server Executable.
	# I am going to try to make the game headless compatible without using a separate Godot binary.
	#print("Server Mode: ", OS.has_feature("Server"))
	
	# It appears my compiled version of Godot's Server cannot use network. It doesn't even show up in Wireshark (and I checked the firewall)
	if(OS.has_feature("Server") == true):
		# If using a servermode engine, set game to servermode
		# I may just listen for command line arguments and not use OS.has_feature(...)
		gamestate.server_mode = true
		
	if gamestate.server_mode:
		# This simulates a windowless server. I do not know if it will work in a true windowless environment (e.g. a dedicated linux server)
		# In that, Godot has official builds for a linux server mode engine which handles the windowless mode automatically.
		
		# when this is true, splash is disabled and background is transparent (also, the window is in borderless mode).
		# The transparent background is still clickable, so change window size to 0 and minimize the window.
		# Also, figure out how to hide the root viewport (or dynamically the children viewports)
		OS.set_window_size(Vector2(0, 0)) # Sets Window Size to 0 (so that it does not intercept clicks to another application)
		OS.set_window_minimized(true) # Minimizes the Window - Shouldn't be necessary since window is already (0, 0), but provides not grabbing control from an invisible window
		
		# This is overkill
		#OS.window_per_pixel_transparency_enabled = true # Turns on Pixel Transparency
		#get_tree().get_root().set_transparent_background(true) # Makes Root Viewport Have a Transparent Background
		#get_tree().get_root().get_node("MainMenu").visible = false # Hides MainMenu
		
		#network.create_server()
		pass
	
	# TODO: Save loaded theme to file that is not accessible to server
	set_theme(gamestate.game_theme) # Sets The MainMenu's Theme
	
# Sets MainMenu Theme
func set_theme(theme) -> void:
	# The set_theme(...) function can only set themes to nodes that are actively loaded (NetworkMenu is not loaded at this point)
	
	#get_tree().get_root().get_node("MainMenu/Menu/Buttons").set_theme(load("res://Themes/default_theme.tres")) # Testing Setting Theme Live - It Works, but I need Control Nodes or Other GUI nodes to set it (e.g. I cannot set it for root)
	#get_tree().get_root().get_node("MainMenu/Menu").set_theme(load(theme)) # This will set the theme for every child of "Menu", that includes the PlayerSelection popup, but not NetworkMenu.
	$Menu.set_theme(theme)
	
	# I May Add The Font To The Theme Instead (then again I may add an override for people to use custom fonts with the same theme)
	var buttons : Node = $Menu/Buttons
	buttons.get_node("Singleplayer").add_font_override("font", load("res://Fonts/dynamicfont/firacode-regular.tres")) # TODO: Fonts will be able to be chosen by player (including custom fonts added by player)
	buttons.get_node("Multiplayer").add_font_override("font", load("res://Fonts/dynamicfont/firacode-regular.tres")) # TODO: Fonts will be able to be chosen by player (including custom fonts added by player)
	buttons.get_node("Options").add_font_override("font", load("res://Fonts/dynamicfont/firacode-regular.tres")) # TODO: Fonts will be able to be chosen by player (including custom fonts added by player)
	buttons.get_node("Quit").add_font_override("font", load("res://Fonts/dynamicfont/firacode-regular.tres")) # TODO: Fonts will be able to be chosen by player (including custom fonts added by player)

# Singleplayer Was Pressed
func _on_Singleplayer_pressed() -> void:
	var player_selection_menu : Node = $Menu/PlayerSelectionMenu/PlayerSelectionWindow
	
	player_selection_menu.popup_centered()
	
# Multiplayer Was Pressed
func _on_Multiplayer_pressed() -> void:
	get_tree().change_scene("res://Menus/NetworkMenu.tscn")

# Options Was Pressed
func _on_Options_pressed() -> void:
	get_tree().change_scene("res://Menus/OptionsMenu.tscn")
	pass

# Quit Was Pressed
func _on_Quit_pressed() -> void:
	get_tree().quit() # Quits Game
