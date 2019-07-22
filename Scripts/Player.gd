extends KinematicBody2D

# Declare member variables here:
const UP = Vector2(0, -1)
const LEFT = Vector2(-1, 0)
const RIGHT = Vector2(1, 0)
const DOWN = Vector2(0, 1)

const ACCELERATION = 50
#const GRAVITY = 20
const MAX_SPEED = 200
#const JUMP_HEIGHT = -500
var friction = false

var motion = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta):
#	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	if is_network_master():
		if Input.is_key_pressed(KEY_W):
			#print("Up")
			motion.y = max(motion.y - ACCELERATION, -MAX_SPEED)
		elif Input.is_key_pressed(KEY_S):
			#print("Down")
			motion.y = min(motion.y + ACCELERATION, MAX_SPEED)
		else:
			friction = true;
			#$Sprite.play("Idle");
			
		if Input.is_key_pressed(KEY_A):
			#print("Left")
			motion.x = max(motion.x - ACCELERATION, -MAX_SPEED)
		elif Input.is_key_pressed(KEY_D):
			#print("Right")
			motion.x = min(motion.x + ACCELERATION, MAX_SPEED)
		else:
			friction = true;
			#$Sprite.play("Idle");
		
		if friction == true:
			motion.x = lerp(motion.x, 0, 0.2)
			motion.y = lerp(motion.y, 0, 0.2)
			friction = false
		
		rpc_unreliable("movePlayer", motion)
		motion = move_and_slide(motion, LEFT)
		
# puppet (formerly slave) sets for all devices except server
puppet func movePlayer(mot):
	motion = move_and_slide(mot, LEFT)
	
	# Note to Godot Developers:
	# There is a bug that setting the floor direction in the game allows players to drag other players (on that player's screen).
	# The coordinates are updated properly so if a new client joins, they will be able to see where the dragged player was dragged to.
	# This is activated by dragging to the direction that is considered the floor.
	# An example is, if UP is set, the player can be dragged downward.
	
	# The workarounds to this issue are to either not set the floor (if gravity is not in use) or to create your own floor checking code.

# Sets Player's Color (also sets other players colors too)
func set_dominant_color(color):
	$CollisionShape2D/Sprite.modulate = color # Changes the Player's Color in the World