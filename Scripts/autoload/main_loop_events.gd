extends Node
class_name MainLoopEvents

#signal resized # Real Window is Resized

# Declare member variables here. Examples:
#var window_size : Vector2 = OS.get_real_window_size()
#var window_size_detection : Thread = Thread.new()

var theme : Theme # Get Game's Theme
var default_font : DynamicFont # Get Default Font
var default_font_size : int # Default Font Size

var game_is_focused : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	theme = gamestate.game_theme # Get Game's Theme
	default_font = theme.get_default_font() # Get Default Font
	default_font_size = default_font.size

	get_tree().set_auto_accept_quit(false) # Disables Default Quit Action - Allows Override to Handle Other Code (e.g. saving or in a meta horror game, play a creepy voice)
	get_tree().connect("files_dropped", self, "_drop_files")
	#get_tree().connect("tree_changed", self, "_tree_changed")
	Input.connect("joy_connection_changed", self, "joy_connection_changed") # Detect Joystick Connection

	# This does not get triggered if stretch mode is viewport
#	get_tree().get_root().connect("size_changed", self, "screen_size_changed")
#	connect("resized", self, "screen_size_changed")
#	window_size_detection.start(self, "_size_change_detector")

	set_process(false)
#	set_process_input(true) #
#	set_process_internal(true) #
#	set_process_priority(100) #
#	set_process_unhandled_input(true) #
#	set_process_unhandled_key_input(true) #
#	set_physics_process(true) #
#	set_physics_process_internal(true) #
#	set_scene_instance_load_placeholder(true) #
#	set_block_signals(false) #

#	Input.joy_connection_changed(0, true, "Name", "GUID") # This can be used to create a virtual controller. Using a custom connection method with a custom sdl mapping can create an InputMap friendly controller that is not standard.

# Called When MainLoop Event Happens
func _notification(what: int) -> void:
	# This isn't an override of the normal behavior, it just allows listening for the events and doing something based on the event happening.

	match what:
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			# This will run no matter if autoquit is on. Disabling autoquit just means that I can quit when needed (so I don't get interrupted, say if I am saving data).
			quit()
		MainLoop.NOTIFICATION_CRASH:
			# When I Was Rewriting the Save Player function, I crashed the game.
			# This print statement was added to stdout, so I know it works.
			# What I can do is save debug info to the hard drive and next time the user loads the game, I can request them to send the info to me.
			logger.trace("Game Is About to Crash!!!")

			var crash_directory : String = OS.get_user_data_dir().plus_file("crash-reports")
			var crash_dir_handler : Directory = Directory.new()
			var crash_system_stats : File = File.new()
			var time : String = str(OS.get_unix_time())

			# Create's Crash Directory If It Does Not Exist
			if not crash_dir_handler.dir_exists(crash_directory): # Check If Crash Logs Folder Exists
				logger.verbose("Creating Crash Logs Folder!!!")
				crash_dir_handler.make_dir(crash_directory)

			OS.dump_memory_to_file(crash_directory.plus_file("crash-%s.mem" % time))
			OS.dump_resources_to_file(crash_directory.plus_file("crash-%s.list" % time))

			crash_system_stats.open(crash_directory.plus_file("crash-system-stats-%s.log" % time), File.WRITE)

			crash_system_stats.store_string("This Log File Is Related (Please Send it Too): %s\n" % logger.log_file_path)
			crash_system_stats.store_string("Command Line Arguments: %s\n" % OS.get_cmdline_args())
			crash_system_stats.store_string("OS Model Name: %s\n" % OS.get_model_name())
			crash_system_stats.store_string("Game Memory Usage: %s/%s\n" % [OS.get_static_memory_usage(), OS.get_static_memory_peak_usage()])
			crash_system_stats.store_string("OS Unique ID: %s\n" % OS.get_unique_id()) # Helps Identify Related Crashes To The Same System - Especially Since Another Program or Driver Could Be The Culprit

			crash_system_stats.store_string("Debug Build: %s\n" % OS.is_debug_build())
			crash_system_stats.store_string("Debug Mode: %s\n" % gamestate.debug)

			# Sometimes the get_stack() function does not return an array that can be converted to string and it crashes the game!!! Ironic, isn't it.
			# Here's the weird part, this crash happens when the game would not crash without the get_stack() function. As in the game runs as if nothing happened.
#			crash_system_stats.store_string("Stack Trace (Currently Not Available For Release Builds): %s\n" % get_stack())
			crash_system_stats.store_string("SceneTree: %s\n" % print_tree_pretty()) # It appears print_tree...() only prints to stdout, so I may not be able to capture it for logging

			crash_system_stats.close()

			#yield(...) - Alert User of Crash With Dialog and Tell Them To Copy Related Files

			quit(397) # Sets Exit Code to 397 to indicate to script game has crashed. I may add more codes and an enum to identify what type of crash it is (if it is something unavoidable, like the system is broken, etc...)
		MainLoop.NOTIFICATION_WM_ABOUT:
			about_game()
		MainLoop.NOTIFICATION_WM_FOCUS_IN:
			game_is_focused = true
		MainLoop.NOTIFICATION_WM_FOCUS_OUT:
			game_is_focused = false
		_: # Default Result - Put at Bottom of Match Results
			pass

# warning-ignore:unused_argument
func _process(delta: float) -> void:
#	var device : int
#	var connected : bool
#	var name : String
#	var guid : String
#
#	Input.joy_connection_changed(device, connected, name, guid)

	pass

func joy_connection_changed(device: int, connected: bool) -> void:
	logger.debug("Device: %s - Connected: %s" % [device, connected])

	if connected:
		Input.start_joy_vibration(device, 1, 1, 0.5) # Vibrate Newly Connected Controller

		logger.debug("Device Name: %s - GUID: %s" % [Input.get_joy_name(device), Input.get_joy_guid(device)])

#func _size_change_detector(_thread_data) -> void:
#	# This function is currently useless as I do not have to manually adjust font sizes anymore.
#	# To save on processing power, I am disabling the while loop.
#
#	while true:
#		yield(get_tree().create_timer(0.5), "timeout")
#
#		if window_size != OS.get_real_window_size():
#			window_size = OS.get_real_window_size()
#			emit_signal("resized")
#
#	# This is currently unreachable code, but it is here so I don't forget it if I change the window size detection later
#	window_size_detection.wait_to_finish() # Close Thread When Finished!!!

# This is supposed to be called last right before the game quits, but that doesn't work (maybe it can only do it in a custom MainLoop?).
# https://docs.godotengine.org/en/3.1/classes/class_mainloop.html#class-mainloop-method-finalize
func _finalize():
	logger.info("Goodbye!!!")

#func screen_size_changed() -> void:
#	# This is supposed to change the font size so the font is smooth.
#	logger.superverbose("Window Size: %s" % window_size)
#	logger.superverbose("Default Font Size: %s" % default_font_size)
#
#	var font_size : int = (((float(window_size.x)) / (float(window_size.y))) * float(default_font_size))
#	var font_size : int = (float(window_size.x)/2) / float(default_font_size)
#	var font_size : int = (((float(window_size.x)) / (float(window_size.y))) * float(default_font_size))
#	font_size = default_font.size + (font_size - default_font.size)
#
#	logger.debug("Font Size: %s" % font_size)
#	logger.debug("Font Size Math: (%s / %s) * %s = %s" % [float(window_size.x), float(window_size.y), float(default_font_size), (float(window_size.x)/float(window_size.y))*float(default_font_size)])
#	logger.debug("Window Size Math: (%s / %s) = %s" % [float(window_size.x), float(window_size.y), float(window_size.x)/float(window_size.y)])
#
#	theme = gamestate.game_theme # Get Game's Theme
#	default_font = theme.get_default_font() # Get Default Font
#	default_font.size = font_size # Change Font Size

# Detect When Files Dropped onto Game (Requires Signal) - Can Work in Any Node
func _drop_files(files: PoolStringArray, from_screen: int):
	# In the right node, this can be used to add mods or add files to a virtual computer (like with Minecraft's ComputerCraft Mod)
	logger.debug("Files Dragged From Screen Number %s: %s" % [from_screen, files])

# Useful when trying to figure out where game froze at. Too bad it doesn't list what part of the tree changed.
func _tree_changed():
	logger.verbose("SceneTree Changed")

# Performs Cleanup When Quitting Game
func quit(error: int = 0):
	OS.set_exit_code(error) # Sets the Exit Code The Game Will Quit With (can be checked with "echo $?" after executing game from shell)

	logger.info("Quit Game!!!")
	get_tree().quit()

# Display Information About Game
func about_game():
	OS.alert(tr("about_game_text"), tr("about_game_title"))

func get_class() -> String:
	return "MainLoopEvents"
