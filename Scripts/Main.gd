#===============================================================================
#             SOURCE CODE FOR 'UNPACKED' - GODOW WILD JAM VERSION                 
#
#                       madparrot.itch.io/unpacked-gwj
#                 github.com/fbcosentino/Unpacked_JamVersion
#-------------------------------------------------------------------------------
#
#                *** FOR LICENSE CHECK THE "LICENSE" FILE ***
#      (But in short: code and nodes are free to use at will, art is not.)
#
# This file is part of the source code for the game Unpacked - Jam Version
# Unpacked is a game initially developed for the Godot Wild Jam - #24, and
# development continued afterwards as a normal full version game. The jam 
# version is open source and released on github.
# This version is made using Godot Engine v3.2.2.stable.official
#
# All the game code, scene files, images, models and music were designed by:
#   Fernando Cosentino
#   github.com/fbcosentino
#
# Except the GWJ art which refers to:
#   Godot Wild Jame
#   godotwildjam.com
#
#===============================================================================


extends Spatial


## 
# This file manages the game session
# When the player starts a new game, a Main object is created
# If the player goes back to main menu to load a new game, Main is
# destroyed and when loading the game a new Main is created
# However, during the same game session Main always persists. So teleporting
# across levels or reloading checkpoints uses the same Main instance.
# Teleporting across levels unloads/instances the "Level" child instead
# Restoring a checkpoint usually happens within the same level since all
# level teleports are also checkpoints, so the Level instance also persists. 
# If for some reason the checkpoint refers to a different level, a level 
# teleport also takes place.

# All triggers work via Main. When player fires a trigger, the signal calls
# a corresponding method here, and all effects are processed in this file.
# The Main has access to the Player, the Level and the WorldEnv nodes while
# the triggers have not, so session-wide tasks must be performed here.




################################################################################
##    CONFIGURATION
## =============================================================================

# === Game Time

# Maximum game time before game over - in minutes
export(float) var MaximumGameTime = 30.0 # 30 mins
# Time HUD configuration
export(float) var ClockStartAngle = 30.0 # In degrees
export(float) var ClockEndAngle = 180.0   # In degrees


# === Camera
export var CameraRotationSpeed = 1.0
# Possible values:
export var CameraAngleNormal = -0.35 # rad ~= -20 deg
export var CameraAngleLookDown = -1.0 # rad ~= -57 deg
# Speed at which we get closer to player to avoid scenario clipping
export var CameraClipSpeed = 10.0 


################################################################################
##    GAME SESSION VARIABLES
## =============================================================================

# Arrays keeping track of interactive objects at reach from player
# pressing the corresponding keys will activate all objects in the
# respective list
var InteractionsAvailable = []
var TrackPointsAvailable = []
var TrackPointsActive = []

# Camera Control variables
var CameraPitch = CameraAngleNormal
var CameraClipPitch = 0.0
var CameraSlopePitch = 0.0
var BehindDistance = 2.0


################################################################################
##    SETUP
## =============================================================================

# Player object
onready var Player = get_node("Player")

# Camera objects
onready var CameraTripod = get_node("CameraTripod") # handles position and yaw
onready var CameraArm = get_node("CameraTripod/CameraArm") # handles tilt
onready var camera = get_node("CameraTripod/CameraArm/Camera") # camera itself
onready var Ray0 = get_node("CameraTripod/CameraArm/RayCast0")
onready var Ray1 = get_node("CameraTripod/CameraArm/RayCast1")
onready var Ray2 = get_node("CameraTripod/CameraArm/RayCast2")
onready var Ray3 = get_node("CameraTripod/CameraArm/RayCast3")
onready var Ray4 = get_node("CameraTripod/CameraArm/RayCast4")

# Level objects
onready var EnvAnims = get_node("EnvironmentAnimations")
onready var TrackingTimer = get_node("TrackingTimer")


# UI objects
onready var Interface = get_node("Interface")
onready var DialogPanel = get_node("Interface/DialogPanel")
onready var DialogLabel = get_node("Interface/DialogPanel/MainLabel")
onready var DialogAnims = get_node("Interface/DialogPanel/AnimationPlayer")

onready var TimeClock = get_node("Interface/TimeClock")
onready var TimeCursor = get_node("Interface/TimeClock/TimeCursor")

onready var LevelLoadingPanel = get_node("Interface/LevelLoadingPanel")
onready var LevelLoadingErrorLabel = get_node("Interface/LevelLoadingPanel/ErrorLabel")

onready var InGameMenu = get_node("Interface/Menu")
onready var InGameMenu_QuitConfirmation = get_node("Interface/Menu/QuitConfirmation")
onready var InGameMenu_CheckpointConfirmation = get_node("Interface/Menu/CheckpointConfirmation")

onready var CheckPointAnim = get_node("Interface/CheckpointHintTexture/AnimationPlayer")
onready var SavedAnim = get_node("Interface/SavedHintTexture/AnimationPlayer")
onready var GameOverAnim = get_node("Interface/GameOverAnim")

var CurrentLevelObject = null
var WorldEnv = null
var BGMusic = null
	
func _ready():
	# Camera RayCast
	Ray1.add_exception(Player)
	Ray2.add_exception(Player)
	
	# Connect user controls signals
	Player.connect("Interact", self, "_on_Player_Interact")
	Player.connect("LookDown", self, "_on_Player_LookDown")
	Player.connect("Tracking", self, "_on_Player_Tracking")
	
	# Set game maximum time in Manager
	Manager.GameMaximumTime = MaximumGameTime
	
	# Reset interface state
	DialogPanel.hide()
	LevelLoadingPanel.hide()
	LevelLoadingErrorLabel.hide()
	InGameMenu.hide()
	InGameMenu_CheckpointConfirmation.hide()
	InGameMenu_QuitConfirmation.hide()
	
	# Clock visibility depends on the saved state
	if Manager.ClockVisible:
		# We use animation here as well instead of TimeClock.show()
		# to make sure the texture alpha is also correct
		TimeClock.get_node("AnimationPlayer").play("ShowClock")
	else:
		# Hiding is simple. It will show via animation later
		TimeClock.hide()
	
	# Load entry level
	CurrentLevelObject = get_node("Level")
	LoadLevelNumber(Manager.CurrentLevel)
	
	
################################################################################
##    LEVEL MANAGEMENT
## =============================================================================

func LoadLevelNumber(level_number):
	# Formats the level number into the level file name
	var level_name = "Level_%02d" % level_number
		
	var is_reload = (level_name == Manager.LastLoadedLevel)
	
	# Load the file name
	LoadLevel(level_name, is_reload)
	
func LoadLevel(level_name, is_reload = false):
	pass
	# Starts asynchronous loading of the level
	# Also handles showing and hiding loading screen
	# Level setup is done at LoadLevelFinish()
	
	# First step, show loading screen
	LevelLoadingErrorLabel.hide()
	LevelLoadingPanel.show()
	
	# Flag we are loading a level. This stops normal game processing 
	Manager.LoadingLevel = true

	# If we are reloading inside the same level, no need to reload
	# the resources. Just reset the animation and player states
	if is_reload:
		LoadLevelFinish()
		return
	
	# Wait one frame so the loading scene shows up
	yield(get_tree(), "idle_frame")
	

	# Otherwise proceed to normal loading

	# Start loading
	Manager.LevelLoader = ResourceLoader.load_interactive('res://Levels/'+level_name+'.tscn')
	# Abort in case of errors
	if Manager.LevelLoader == null:
		print("Could not load level "+level_name+".tscn")
		LevelLoadingErrorLabel.show()
		return

		
	# Otherwise get rid of the old level
	if CurrentLevelObject != null:
		# Fade out BGM
		if BGMusic != null:
			BGMusic.play("FadeOut")
			yield(BGMusic, "animation_finished")
		
		CurrentLevelObject.hide()
		CurrentLevelObject.queue_free()
		yield(get_tree(), "idle_frame")
		
	Manager.LastLoadedLevel = level_name



func LoadLevelFinish():
	# Called when loading a level finishes. 
	# Prepares the level and starts gameplay
	
	
	# Get reference for the level's WorldEnvironment
	# This is required for the sniffing/tracking effect
	WorldEnv = CurrentLevelObject.get_node("WorldEnv")

	# Background music
	BGMusic = CurrentLevelObject.get_node("BGMusic/AnimationPlayer")
	
	# Reposition the player
	Player.global_transform.origin = Manager.PlayerCheckPoint
	# Turn the player
	Player.rotation.y = Manager.PlayerCheckPointRotation
	
	# Wait an idle frame for all _ready() methods to process
	# This is important for all trigger objects to register themselves
	yield(get_tree(), "idle_frame")
	
	# Set all animations to their saved state values
	if Manager.CurrentLevel in Manager.TrackedAnimations:
		var tracked_dict = Manager.TrackedAnimations[Manager.CurrentLevel]
		# Traverse all tracked items
		for item_key in tracked_dict:
			# Extract fields from this item
			var item_array = Utils.SplitPlayerAndAnimation(item_key)
			var anim_node = get_node(NodePath(item_array[0]))
			var anim_name = item_array[1]
			var anim_state = tracked_dict[item_key]
			# Integrity check:
			if (anim_node != null) and (anim_name != ""):
				# Do we have to move animation to completion?
				if anim_state == Utils.ANIM_TRACK_MODE.IsCompleted:
					# Move the animation to last frame
					anim_node.play(anim_name, -1, 1.0, true)
				# Do we have to set it playing?
				elif anim_state == Utils.ANIM_TRACK_MODE.IsPlaying:
					# Play the animation
					anim_node.play(anim_name)
				else:
					# Call the reset state
					anim_node.play("Reset")

					
	# Reset environment animation due to tracking effect
	EnvAnims.play("TrackingOff", -1, 1.0, true)
	
	# Make a last save state to store registered animation states
	Manager.SaveGameCheckPoint()


	# Flag we are no longer loading a level. This resumes normal game processing 
	Manager.LoadingLevel = false

	# Hide loading screen
	LevelLoadingPanel.hide()
	



################################################################################
##    GAMEPLAY
## =============================================================================
	
func _input(event):
	# If this is a keyboard key press, pressed down and not while holding
	#if (event is InputEventKey) and (event.pressed) and (not event.echo):
		
		# ESC key
		#if event.scancode == KEY_ESCAPE:
	if Input.is_action_just_pressed("menu"):
		# Toggles menu visibility
		
		# If we are in game over sequence, abort
		if Manager.IsGameOver:
			return
		
		# If not visible, show
		if not InGameMenu.visible:
			ShowMenu()
		# Otherwise, hide
		# This will also push away any sub-screens or focus selections
		else:
			HideMenu()
		

func _process(delta):
	# Handles main game session display processing and level management
	
	
	
	# === LEVEL LOADING
	# Level loading is not affected by IsPaused
	
	# Are we loading a level via ResourceInteractiveLoader?
	if Manager.LoadingLevel:
		# Logic integrity check
		if Manager.LevelLoader == null:
			# Something really wrong happened.
			# Bring stuff back to minimize user frustration
			LevelLoadingErrorLabel.show()
			print("Loader is null")
			LoadLevelFinish()
			return
			
		# Load another atom from the level
		var result = Manager.LevelLoader.poll()
		# Do we still have loading work?
		if result == OK:
			# Currently we do nothing. Let player observe the fox a bit
			pass
		
		# Are we done?
		elif result == ERR_FILE_EOF:
			# File loading is completed. Get the data
			var level_scene = Manager.LevelLoader.get_resource()
			# Release the loader
			Manager.LevelLoader = null
			# Instance the level
			# Player and camera objects are outside the level
			# It is important we DO NOT change the player position
			# since all levels have their geometry synchronized
			CurrentLevelObject = level_scene.instance()
			CurrentLevelObject.name = 'Level'
			add_child(CurrentLevelObject)
			# Finally finish the loading process by resuming game
			LoadLevelFinish()
		
		# Did we hit any errors?
		else:
			# In this version bring stuff back to minimize user frustration
			# For future improvement: make a new fresh attempt
			LevelLoadingErrorLabel.show()
			print("Error loading level: result=%d" % result)
			# Release the loader
			Manager.LevelLoader = null
			
	
	# === NORMAL GAMEPLAY
	
	# Otherwise, process camera
	# Camera position is not affected by IsPaused
	else:
		
		# If we are in game over sequence, abort
		if Manager.IsGameOver:
			return
		
		# Camera position is set to player position
		CameraTripod.global_transform.origin = Player.global_transform.origin
	
		# For rotation, we interpolate
		
		# Yaw
		CameraTripod.rotation.y = lerp_angle(CameraTripod.rotation.y, Player.rotation.y, CameraRotationSpeed*delta)

		# Pitch
		# Pitch coming from obstructed area behind must be fast
		# Other factors are slow

		# Normal factors - slope and abyss edge
		CameraSlopePitch = lerp_angle(CameraSlopePitch, CameraPitch + Player.SlopeAngle, CameraRotationSpeed*delta)
		
		CameraArm.rotation.x = CameraClipPitch + CameraSlopePitch

		# Zoom due to obstructed area behind
		camera.translation.z = lerp(camera.translation.z, BehindDistance-0.1, CameraClipSpeed*delta)

func _physics_process(delta):
	# Physics processing is used to tick the in-game time clock
	# due to it's fixed time step reliability
	# and to correct camera position based on collisions
	
	# In-game time *IS* affected by IsPaused
	# We only track time if Clock HUD is already visible
	if (not Manager.IsPaused) and Manager.ClockVisible:
		Manager.GameTime += delta
		UpdateGameTime()
	
	# GameOver
	if not (Manager.IsGameOver) and (Manager.GameTime > (MaximumGameTime * 60.0)):
		GameOver()


	# If we are in game over sequence, abort
	if Manager.IsGameOver:
		return
		
	# === RayCast for camera position
	
	# Default ray points - end of line
	var ray_dist = 2.0
	# If the rays intersect something, we update the values
	# This means there is not enough room for the camera
	# Traverses all rays used - we could have used get_children()
	# followed by if "is RayCast" but with this array we avoid processing
	for ray in [Ray0, Ray1, Ray2, Ray3, Ray4]:
		if ray.is_colliding():
			# Uses min() to always get the lowest value between
			#  current and previous
			ray_dist = min(ray_dist, (ray.get_collision_point() - ray.global_transform.origin).length())
	# Now ray_dist is the distance of the shortest hitting ray
		
	BehindDistance = ray_dist

func StartClock():
	pass
	# Resets the time and shows the clock HUD
	Manager.GameTime = 0.0
	# Update dial position
	UpdateGameTime()
	# Track clock as visible in Manager
	Manager.ClockVisible = true	
	# Show HUD
	TimeClock.get_node("AnimationPlayer").play("ShowClock")
	
func HideClock():
	# Track clock as not visible in Manager
	Manager.ClockVisible = false
	# Hides the clock HUD
	TimeClock.get_node("AnimationPlayer").play("HideClock")
	

func UpdateGameTime():
	# Calculates elapsed time and updates the dial
	
	# Get a normalized (range [0.0, 1.0]) value for elapsed time
	var elapsed_norm = Manager.GameTime / (MaximumGameTime * 60.0)
	# Angle range for the time range
	var angle_range = ClockEndAngle - ClockStartAngle
	# Set the dial rotation
	TimeCursor.rect_rotation = ClockStartAngle + (elapsed_norm * angle_range)

# =====================================
# Player controls callbacks

func _on_Player_Interact():
	# If we are in a dialog, this is priority
	if Manager.InDialog:
		# If we are allowed to interact - that is, not in a transition
		if not Manager.InDialogTransition:
			# Hide the dialog
			ContinueDialog()
		
	else:
		# Activate all interactions at range
		for interaction_area in InteractionsAvailable:
			ActivateInteraction(interaction_area)

func _on_Player_Tracking():
	# Tracking action only works if we are not in a dialog
	if not Manager.InDialog:
		# Activate all tracks at range
		for track_point in TrackPointsAvailable:
			ActivateTrackPoint(track_point)

func _on_Player_LookDown(enabled):
	# Sets the target pitch angle used by _process()
	
	# If we are to look down, set the look down angle to camera
	if enabled:
		CameraPitch = CameraAngleLookDown
		
	# Otherwise reset camera to normal angle
	else:
		CameraPitch = CameraAngleNormal


	
################################################################################
## TRIGGER CALLBACKS
## =============================================================================

func _on_NarratorTrigger(body, sender):
	# This method is called when the player hits a NarratorTrigger object
	if body.name != "Player":
		return
		
	# Ignore disabled triggers
	if not sender.Enabled:
		return
	
	# === Did we not fire already?
	if not (Manager.CurrentLevel in Manager.FiredDialogs):
		Manager.FiredDialogs[Manager.CurrentLevel] = {}
	if not (sender.name in Manager.FiredDialogs[Manager.CurrentLevel]):
		# Set up fire counter
		Manager.FiredDialogs[Manager.CurrentLevel][sender.name] = 1
	else:
		# Add this fire to the counter
		Manager.FiredDialogs[Manager.CurrentLevel][sender.name] += 1
		
	# Get the counter into a variable for semantic/readability reasons
	var count = Manager.FiredDialogs[Manager.CurrentLevel][sender.name]
	
	# Should we stop showing this after some time?
	var too_late = ((sender.StopAfter > 0) and (count > sender.StopAfter))
	# Should we avoid showing this before a few times?
	var too_soon = (count <= sender.OnlyShowAfter)
	
	# Finally, are we allowed to show the dialog?
	if (not too_soon) and (not too_late):
		# Fire the narrator dialog
		ShowDialog(sender.Texts, sender.Freeze)
		
		# (Optional) Are we to play an animation
		if sender.TriggerAnimationPlayerNode != null:
			sender.TriggerAnimationPlayerNode.play(sender.TriggerAnimationName)
			
		# (Optional) Should we push the player towards any direction?
		# (e.g. avoid entering an area)
		if sender.PushPlayer.length() > 0.0:
			# Get the vector in global frame
			var push_vec = sender.to_global(sender.PushPlayer) - sender.global_transform.origin
			# Add vector to player push vector
			Player.PushedVector += push_vec
			
		# (Optional) Should any extra action take place?
		# Start clock
		if sender.ExtraAction == Utils.NARRATOR_ACTION.StartClock:
			StartClock()

func _on_CheckPoint(body, sender):
	# If the collision is not with player, abort
	if body.name != "Player":
		return

	# If we are in game over sequence, abort
	if Manager.IsGameOver:
		return
	
	# All checkpoints store currentl player location and y rotation
	# they can optionally change level
	
	# Store player position/rotation
	if sender.CorrectPosition:
		# If we have to correct position, use checkpoint position instead
		HitCheckPoint(sender.global_transform.origin)
	else:
		# Normal checkpoint hitting, using player position
		HitCheckPoint()
	
	# Do we load another level?
	if sender.ChangeLevel:
		# Store level number in Manager
		Manager.CurrentLevel = sender.Level

		# Make a snapshot of current game state again
		# since we changed the level
		Manager.SaveGameCheckPoint()
		# There will be a third one right after loading the level

		# Load the level
		LoadLevelNumber(sender.Level)

func _on_InteractionArea_Available(sender, state):
	# Interaction area entered range
	if state:
		# Add this interaction area to list
		InteractionsAvailable.append(sender)
		
	# Interaction area left range
	else:
		# Remove this interaction area from list
		InteractionsAvailable.erase(sender)
	
func _on_TrackPoint_Available(sender, state):
	# Track point entered range
	if state:
		# Add this interaction area to list
		TrackPointsAvailable.append(sender)
		
	# Track point left range
	else:
		# Remove this interaction area from list
		TrackPointsAvailable.erase(sender)
	
func _on_GameComplete(body):
	# If the collision is not with player, abort
	if body.name != "Player":
		return

	# This signal just fires the GameComplete() method, transparently
	GameComplete()
	

################################################################################
## GAME MECHANICS
## =============================================================================

func GoToCheckPoint():
	# Restores internal state from last checkpoint
	Manager.RestoreGameCheckPoint()
	# Reloads the level bringing back all objects/animations
	LoadLevelNumber(Manager.CurrentLevel)
	
func HitCheckPoint(custom_position = null):
	# Saves player position as checkpoint
	# if custom_position is provided, use that instead
	# of player global_transform.origin
	# Finally, stores a snapshot of current game state
	
	if custom_position != null:
		Manager.PlayerCheckPoint   = custom_position
	else:
		Manager.PlayerCheckPoint   = Player.global_transform.origin
	# Rotation is always player rotation anyway
	Manager.PlayerCheckPointRotation = Player.rotation.y
	# Make a snapshot of current game state
	Manager.SaveGameCheckPoint()
	# Play animation
	CheckPointAnim.play("HitCheckpoint")
	
func ShowDialog(text, freeze = false):
	# Shows the dialog box, or adds more messages to the queue
	# If freeze == true, prevents user interaction before dismissing this
	
	# If there are no messages, abort
	if (not text is Array) or (text.size() == 0):
		return
	
	# Set dialog variables firing first message
	# We concatenate the arrays to make sure we don't assign a reference
	# This also allows us to stack dialogs which fire too close
	Manager.CurrentDialogText = Manager.CurrentDialogText+text
	# Do we disable the player controls?
	if freeze:
		# We use IF here since we don't want Manager.InDialogFreeze = false
		# Only the end of a dialog is capable of setting it to false
		Manager.InDialogFreeze = true

	# If we were not previously in a dialog
	if not Manager.InDialog:
		# We are now
		# Setting this flag will cause following calls to ShowDialog()
		# to stack messages not showing them. This is important since
		# we yield the frame here
		Manager.InDialog = true
		# If Set first message
		Manager.DialogMessageIndex = 0
		DialogLabel.bbcode_text = text[0]
	
		# Flag transition to disable pressing E again
		Manager.InDialogTransition = true
		# Show Dialog box
		DialogAnims.play("FadeIn")
		# Wait until the animation is over
		yield(DialogAnims, "animation_finished")
		# Flag transition is over - may press E again
		Manager.InDialogTransition = false

	# Otherwise just let the stack do its job
	
	
func ContinueDialog():
	# Either shows next dialog 
	# or dismisses it if nothing else to show
	
	# Next id
	Manager.DialogMessageIndex += 1
	
	# Do we have more messages to show?
	if Manager.DialogMessageIndex < Manager.CurrentDialogText.size():
		# Flag transition to disable pressing E again
		Manager.InDialogTransition = true
		# Hide dialog box
		DialogAnims.play("FadeOut")
		# Wait until the animation is over
		yield(DialogAnims, "animation_finished")
		# Set the next message
		DialogLabel.bbcode_text = Manager.CurrentDialogText[Manager.DialogMessageIndex]
		# Show Dialog box
		DialogAnims.play("FadeIn")
		# Wait until the animation is over
		yield(DialogAnims, "animation_finished")
		# Flag transition is over - may press E again
		Manager.InDialogTransition = false
		
	# Done, dismiss dialog
	else:
		# Reset the variables
		Manager.InDialog = false
		Manager.InDialogFreeze = false
		Manager.InDialogTransition = false
		Manager.DialogMessageIndex = 0
		Manager.CurrentDialogText.clear()
	
		# Flag transition to disable pressing E again
		Manager.InDialogTransition = true
		# Hide the dialog
		DialogAnims.play("FadeOut")
		# Wait until the animation is over
		yield(DialogAnims, "animation_finished")
		# Flag transition is over - may press E again
		Manager.InDialogTransition = false
	

func ToggleTrackingEffect(enabled = false):
	# Toggles the effects used in the sniffing/tracking mechanic
	
	# Turn effects on:
	if enabled:
		EnvAnims.play("TrackingOn")
		
	# Restore normal appearance
	else:
		EnvAnims.play("TrackingOff")
		
		
		
func ActivateInteraction(interaction_area):
	# === Did we not fire already?
	if not (Manager.CurrentLevel in Manager.FiredDialogs):
		Manager.FiredDialogs[Manager.CurrentLevel] = {}
	if not (interaction_area.name in Manager.FiredDialogs[Manager.CurrentLevel]):
		# Set up fire counter
		Manager.FiredDialogs[Manager.CurrentLevel][interaction_area.name] = 1
	else:
		# Add this fire to the counter
		Manager.FiredDialogs[Manager.CurrentLevel][interaction_area.name] += 1
		
	# Update hint visibility
	interaction_area.UpdateVisibility()
		
	# Get the counter into a variable for semantic/readability reasons
	var count = Manager.FiredDialogs[Manager.CurrentLevel][interaction_area.name]
	
	# Should we stop showing this after some time?
	var too_late = ((interaction_area.StopAfter > 0) and (count > interaction_area.StopAfter))
	# Should we avoid showing this before a few times?
	var too_soon = (count <= interaction_area.OnlyShowAfter)
	
	# Finally, are we allowed to show the dialog?
	if (not too_soon) and (not too_late):
		# Show the interaction dialog
		ShowDialog(interaction_area.Texts, interaction_area.Freeze)

		# (Optional) If we are to play an animation
		if interaction_area.TriggerAnimationPlayerNode != null:
			interaction_area.TriggerAnimationPlayerNode.play(interaction_area.TriggerAnimationName)
		
		# Does this interaction trigger give any skill?
		match interaction_area.GiveSkill:
			# DOUBLE JUMP
			Utils.SKILLS.DoubleJump:
				Manager.HasDoubleJump = true


func ActivateTrackPoint(_fired_track_point):
	# Fires the tracking effect for this particular track point
	
	# If we are already tracking something, abort
	if Manager.InTracking:
		return
	
	# We must keep track of the track points activated
	# so we know what to deactivate later
	TrackPointsActive.clear()
	
	# Activate all available tracking points
	for track_point in TrackPointsAvailable:
		# Only process trackpoints which are enabled
		if track_point.Enabled:		
			# Add this trackpoint to list of active ones
			TrackPointsActive.append(track_point)
			# Activate it
			track_point.ToggleEffect(true)
			
	# If at least one trackpoint was activated:
	if TrackPointsActive.size() > 0:
		# Activate environment effect
		ToggleTrackingEffect(true)
	
		# Set the timer to deactivate
		TrackingTimer.start(Manager.TrackingDuration)
		
		# Set the Manager flag
		Manager.InTracking = true



func _on_TrackingTimer_timeout():
	# Tracking skill has elapsed, deactivate effects
	# This time we do not use TrackpointsAvailable because the
	# player has moved, we use TrackPointsActive instead
	for track_point in TrackPointsActive:
		# Deactivate
		track_point.ToggleEffect(false)
		# Remove from active list
		TrackPointsActive.erase(track_point)

	# Make sure the list is clear in case something wrong
	# happened in the loop above. Failsafe call
	TrackPointsActive.clear()

	# Deactivate environment effect
	ToggleTrackingEffect(false)

	# Clear the manager flag
	Manager.InTracking = false


################################################################################
## IN-SESSION MENU
## =============================================================================

func ShowMenu():
	# Pauses the game and shows the in-session menu
	# Pause is not really a pause as the animations are supposed
	# to keep playing. It justs stops gameplay features including time
	
	# Pause the game
	Manager.IsPaused = true
	
	# Set the focus to "Return to game" button
	InGameMenu.get_node("BtnBackToGame").grab_focus()
	
	# Show menu UI
	InGameMenu.show()
	InGameMenu_QuitConfirmation.hide()
	
func HideMenu():
	# Hides the in-session menu and unpauses the game

	# Hide menu UI
	InGameMenu.hide()
	InGameMenu_QuitConfirmation.hide()
	InGameMenu_CheckpointConfirmation.hide()

	# Unpause the game
	Manager.IsPaused = false


func GameOver():
	# Fires game over sequence
	Manager.IsGameOver = true
	# Play fading out animation - shared between GameOver and GameComplete
	GameOverAnim.play("GameOver")
	# Wait for it to finish
	yield(GameOverAnim, "animation_finished")
	# Unload the entire Main scene and load game over scene
	var _error = get_tree().change_scene("res://Scenes/GameOver.tscn")

func GameComplete():
	# Fires game complete sequence
	Manager.IsGameOver = true
	# Play fading out animation - shared between GameOver and GameComplete
	GameOverAnim.play("GameOver")
	# Wait for it to finish
	yield(GameOverAnim, "animation_finished")
	# Unload the entire Main scene and load game complete scene
	var _error = get_tree().change_scene("res://Scenes/GameComplete.tscn")


func _on_Menu_BtnBackToGame_pressed():
	# Return to game
	HideMenu()

func _on_Menu_BtnSaveGame_pressed():
	# Save game
	Manager.SaveGameToFile()
	# Return to game
	HideMenu()
	# Show "game saved" hint animation
	SavedAnim.play("Saved")

func _on_Menu_BtnBackToCheckpoint_pressed():
	# Show screen asking confirmation to discard current progress
	# and reload from the last checkpoint
	
	# Show confirmation screen
	InGameMenu_CheckpointConfirmation.show()
	# Move focus to Cancel button - safe in case of accidental double key hit
	InGameMenu_CheckpointConfirmation.get_node("BtnCancel").grab_focus()


func _on_Menu_CheckPoint_BtnCancel_pressed():
	# Cancel restoring a checkpoint
	
	# Show confirmation screen
	InGameMenu_CheckpointConfirmation.hide()
	# Set the focus to "Return to game" button
	InGameMenu.get_node("BtnBackToGame").grab_focus()


func _on_Menu_CheckPoint_BtnConfirm_pressed():
	# Discard current progress and reload game from checkpoint

	# Hide menu, and most importantly, restore game pause state
	HideMenu()

	# Restore checkpoint
	GoToCheckPoint()

func _on_Menu_BtnQuitToIntro_pressed():
	# Show screen asking confirmation with a sad face
	# Sad face is important: one needs a heartless cold mind to leave
	# this gorgeous fox alone in the darkness of a quitted game
	
	# Show confirmation screen
	InGameMenu_QuitConfirmation.show()
	# Move focus to Cancel button - we want to go back to game, of course
	InGameMenu_QuitConfirmation.get_node("BtnCancel").grab_focus()


func _on_Menu_Quit_BtnCancel_pressed():
	# Thankfully the user has given up quitting
	# ("Quits to quit"?)
	
	# Hide confirmation screen
	InGameMenu_QuitConfirmation.hide()
	# Set the focus to "Return to game" button
	InGameMenu.get_node("BtnBackToGame").grab_focus()


func _on_Menu_Quit_BtnConfirm_pressed():
	# Quitting the game moves back to intro screen
	# It's a fast-loading one, no need for loading animations
	
	# In fact, we do not reset any player variable here
	# so it is technically possible to resume game
	# even after going back to intro screen

	# Hide menu, and most importantly, restore game pause state
	HideMenu()
	
	Manager.LastLoadedLevel = ""
	
	# Load intro screen
	var _error = get_tree().change_scene("res://Scenes/Intro.tscn")




