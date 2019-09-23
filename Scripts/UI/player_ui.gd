extends CanvasLayer
class_name PlayerUI

# Signals
signal cleanup_ui

# Declare member variables here. Examples:
onready var panelPlayerList : Node = $panelPlayerList
onready var panelChat : Node = $panelChat
# warning-ignore:unused_class_variable
onready var panelStats : Node = $panelPlayerStats
onready var pauseMenu : Node = $PauseMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
#	set_process(true)

	set_theme(gamestate.game_theme)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta: float) -> void:
#	pass

func _input(event) -> void:
	# Checks to See if connected to server (if not, just return)
	if not get_tree().has_network_peer() or not network.connected:
		return

	# This allows user to see player list (I will eventually add support to change keys and maybe joystick support)
	if event.is_action("show_playerlist") and !pauseMenu.paused:
		panelPlayerList.show_player_list()

	if event.is_action_released("show_playerlist") and !pauseMenu.paused :
		panelPlayerList.hide_player_list()

	if event.is_action_pressed("pause") and !pauseMenu.visible:
		pauseMenu.pause()
	elif event.is_action_pressed("resume") and pauseMenu.visible:
		pauseMenu.resume()


	# Makes Chat Window Visible
	if event.is_action_pressed("chat_command") and !pauseMenu.paused and !panelChat.visible and !is_calc_open():
		panelChat.show_panelchat()
		panelChat.get_node("userChat").grab_focus() # Causes LineEdit (where user types) to grab focus of keyboard
		panelChat.get_node("userChat").set_text("") # Replaces text with a Forward Slash
		panelChat.get_node("userChat").set_cursor_position(1) # Moves Caret In Front of Slash
		panelChat.just_opened = true

	if event.is_action_pressed("chat_show") and !pauseMenu.paused and !panelChat.visible and !is_calc_open():
		panelChat.show_panelchat()
		panelChat.get_node("userChat").grab_focus() # Causes LineEdit (where user types) to grab focus of keyboard
		panelChat.just_opened = true

	# Makes Chat Window Invisible
	if event.is_action_pressed("chat_hide") and !pauseMenu.paused and panelChat.visible:
		panelChat.hide_panelchat()

	# Closes Connection (Client and Server)
	# I plan on replacing this with a "pause" menu - it will only pause on singleplayer
	if event.is_action_pressed("quit_world") and !panelChat.visible:
		# TODO: Replace Me Soon
		network.close_connection()

# Make Sure Game Saves World On Quit or Crash
func _notification(what: int) -> void:
	# This isn't an override of the normal behavior, it just allows listening for the events and doing something based on the event happening.

	match what:
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			# This will run no matter if autoquit is on. Disabling autoquit just means that I can quit when needed (so I don't get interrupted, say if I am saving data).
			if not get_tree().has_network_peer():
				return

			network.close_connection()
			logger.info("Saved Worlds On Quit!!!")
			#main_loop_events.quit()
		MainLoop.NOTIFICATION_CRASH:
			# I don't know if this will work on crash as I have not had an opportunity to properly crash my game to test it.
			if not get_tree().has_network_peer():
				return

			network.close_connection()
			logger.info("Saved Worlds On Crash!!!")

# Cleanup PlayerUI
func cleanup() -> void:
	#logger.verbose("Cleanup PlayerUI")
	emit_signal("cleanup_ui") # Both Standard Code and Modded Code Should Listen for this Signal

# Sets PlayerUI Theme
func set_theme(theme) -> void:
	$panelPlayerList.set_theme(theme)
	$panelPlayerStats.set_theme(theme)
	$panelChat.set_theme(theme)

# Checks if Calculator is Open (from Easter Eggs)
func is_calc_open() -> bool:
	return get_tree().get_root().has_node("Calculator")

func get_class() -> String:
	return "PlayerUI"
