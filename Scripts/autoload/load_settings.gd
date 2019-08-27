extends Node

# Used to load settings from options menu

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	logger.create_log()
	
	TranslationServer.set_locale("pr")
	logger.debug("Locale: %s" % TranslationServer.get_locale())
	logger.debug("Name: %s" % TranslationServer.get_locale_name(TranslationServer.get_locale()))
	
	#OS.window_fullscreen = true # Allows Enabling Full Screen
	#OS.set_window_size(Vector2(640, 480)) # Sets Window's Size
	logger.verbose("Window Size: %s" % OS.get_window_size()) # Get's Window Size Including Titlebar
	#logger.verbose("Real Window Size: %s" % OS.get_real_window_size()) # Gets Window's Size Minus Titlebar
	#logger.verbose("Screen Size: %s" % OS.get_screen_size()) # Gets Screen Size
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
