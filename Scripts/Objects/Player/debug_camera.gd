extends Camera2D
class_name DebugCamera

# NOTE (IMPORTANT): The coordinates are measured in pixels.
# The tilemap quadrant size is 16x16 blocks
# The block size is 32x32 pixels.
# To convert coordinates to chunk positions you need to run the formula ((coordinate_x_or_y/16)/32)
# The decimal after the chunk position shows where in the chunk the coordinate is located (if no decimal, then you are at the start of the chunk).
# You may have to give or take a one depending on if the coordinate was negative or positive.

# Declare member variables here. Examples:
var cam_speed : int = 70
var player : Node
var powerstate_status : String

onready var coor_label = $PlayerCoordinates
onready var cam_coor_label = $CameraCoordinates
onready var chunk_position_label = $ChunkPosition
onready var world_name_label = $WorldName
onready var fps_label = $FPS
onready var physics_fps_label = $PhysicsFPS
onready var battery_label = $BatteryStats

# warning-ignore:unused_class_variable
onready var crosshair = $Crosshair

onready var world : Node = get_parent().get_parent()
onready var world_generator : Node = world.get_node("Viewport/WorldGrid/WorldGen")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_theme(gamestate.game_theme)
	
	world_generator.connect("chunk_change", self, "update_chunk_label")
	get_tree().get_root().connect("size_changed", self, "screen_size_changed")
	
	update_world_label()
	
	set_physics_process(true)
	
	player = get_player_node()
	
	update_camera_pos(player.position)
	update_crosshair_pos(player.position)
	update_camera_pos_label()
	update_battery_label()

func screen_size_changed() -> void:
	update_crosshair_pos(player.position)

func _process(_delta: float) -> void:
	update_fps_label()
	update_battery_label()

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("debug_up"):
		translate(Vector2(0, -cam_speed))
		update_camera_pos_label()
	if Input.is_action_pressed("debug_down"):
		translate(Vector2(0, cam_speed))
		update_camera_pos_label()
	if Input.is_action_pressed("debug_left"):
		translate(Vector2(-cam_speed, 0))
		update_camera_pos_label()
	if Input.is_action_pressed("debug_right"):
		translate(Vector2(cam_speed, 0))
		update_camera_pos_label()
	
	update_player_pos_label()
	update_physics_fps_label()

func get_player_node() -> Node:
	#logger.verbose("Parent: %s" % get_parent().name)
	
	var players : Node
	if get_parent().has_node("WorldGrid/Players"):
		players = get_parent().get_node("WorldGrid/Players")
	
	return players.get_node(str(gamestate.net_id)).get_node("KinematicBody2D")
	
func update_chunk_label(chunk: Vector2) -> void:
	chunk_position_label.text = tr("debug_chunk_label") % chunk
	
func update_battery_label() -> void:
	match OS.get_power_state():
		OS.POWERSTATE_UNKNOWN:
			powerstate_status = tr("battery_unknown")
		OS.POWERSTATE_ON_BATTERY:
			powerstate_status = tr("battery_battery")
		OS.POWERSTATE_NO_BATTERY:
			powerstate_status = tr("battery_none")
		OS.POWERSTATE_CHARGING:
			powerstate_status = tr("battery_charging")
		OS.POWERSTATE_CHARGED:
			powerstate_status = tr("battery_charged")
	
	battery_label.text = tr("battery_label") % [OS.get_power_percent_left(), OS.get_power_seconds_left(), powerstate_status]
	
func update_fps_label() -> void:
	fps_label.text = tr("fps_label") % [Engine.get_frames_per_second(), Engine.get_frames_drawn()]
	
func update_physics_fps_label() -> void:
	physics_fps_label.text = tr("physics_fps_label") % [Engine.get_iterations_per_second()]
	
func update_world_label():
	world_name_label.text = tr("world_name_label") % world.name
	
func update_player_pos_label() -> void:
	# Player's position is based on center of Player, not the edges
	if player != null:
		coor_label.text = tr("player_coordinate_label") % player.position
	
func update_camera_pos_label() -> void:
	# Get Builtin Screen Size and Find center of screen (add center coordinates to coordinates of camera)
	# This helps locate where the crosshair is (which is only a visual reference for the user. The gdscript does not get position from crosshair)
#	var cross_x = self.position.x + (ProjectSettings.get_setting("display/window/size/width")/2)
#	var cross_y = self.position.y + (ProjectSettings.get_setting("display/window/size/height")/2)

#	var cross_x = self.position.x + (get_viewport().get_visible_rect().size.x/2)
#	var cross_y = self.position.y + (get_viewport().get_visible_rect().size.y/2)

	var cross_x = self.position.x + (get_tree().get_root().size.x/2)
	var cross_y = self.position.y + (get_tree().get_root().size.y/2)

	var cross_coor = Vector2(cross_x, cross_y)
	
	# Prints center of screen's position in world
	cam_coor_label.text = tr("camera_coordinate_label") % str(cross_coor)

# Relocate Camera to this Specified Position (in middle of screen)
func update_camera_pos(position: Vector2) -> void:
	# Fix this to make it center on player no matter what the screen size is (When stretch mode is disabled)
	
	var cross_x = position.x - (ProjectSettings.get_setting("display/window/size/width")/2)
	var cross_y = position.y - (ProjectSettings.get_setting("display/window/size/height")/2)
	
#	var cross_x = position.x - (get_viewport().get_visible_rect().size.x/2)
#	var cross_y = position.y - (get_viewport().get_visible_rect().size.y/2)
	
#	var cross_x = position.x - (get_tree().get_root().size.x/2)
#	var cross_y = position.y - (get_tree().get_root().size.y/2)
	
	self.position = Vector2(cross_x, cross_y)

func update_crosshair_pos(position: Vector2) -> void:
	# Fix this so that it positions the label exactly in the middle instead of near it.
	
#	var cross_x = OS.get_real_window_size().x/2
#	var cross_y = OS.get_real_window_size().y/2
	
#	var cross_x = get_tree().get_root().size.x/2
#	var cross_y = get_tree().get_root().size.y/2
#
#	print("Camera Label Position: (%s, %s)" % [cross_x, cross_y])
#	crosshair.rect_position = Vector2(cross_x, cross_y)
	
	pass

func set_theme(theme: Theme) -> void:
	coor_label.set_theme(theme)
	cam_coor_label.set_theme(theme)
	chunk_position_label.set_theme(theme)
	world_name_label.set_theme(theme)
	fps_label.set_theme(theme)
	physics_fps_label.set_theme(theme)
	battery_label.set_theme(theme)

func get_class() -> String:
	return "DebugCamera"
