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


extends Node


##
# Manager takes care of tasks outside o a game session - that is, must be
# available even before starting a new game, as well as during the session.
# Examples are saving/loading game state, managing connected gamepads, etc.
# Since it is a singleton (while Main is not), it is also used to store
# some game session variables (even if Main is responsible for game sessions)
# so they are more easily accessible to nodes around the code.


################################################################################
##    GAME STATE
## =============================================================================

# Game pause is done via internal variable
# We want the animations to keep playing (since they are used to
# make animals feel alive), but prevent user interaction and
# time elapsing
var IsPaused = false

# Once the game over sequence is initiated the player can no
# longer access the menu hitting ESC
# This flag indicates if such a sequence has started
var IsGameOver = false

# In-Game Time Clock
# Stored as UNIX EPOCH, but float to accomodate fraction of second
var GameTime = 0.0
var GameMaximumTime = 30.0 # minutes
# Tracks if clock HUD is visible
var ClockVisible = false

# Progress
var CurrentLevel = 1
var LastLoadedLevel = ""
var PlayerCheckPoint = Vector3(0.0, 0.0, 0.0)
var PlayerCheckPointRotation = 0.0 # Y rotation

# Skills
var HasDoubleJump = true
var TrackingDuration = 5.0

# Tracks fired dialogs to keep one-shot dialog state in saved states
# FiredDialogs[ level number ][ Node name ] = counter
var FiredDialogs = {}

# Stores a list of animations to track position in saved state
# We use a string combining the nodepath and the animation name
# so we can easily track if the combination exists in the array
# TrackedAnimations[ level number ] = {
#	str(AnimationPlayer node path + ';' + animation name) : frame number
#   ...
# }
var TrackedAnimations = {}


# Checkpoint saved state in JSON string
# This string is updated whenever touching a checkpoint
# When the player asks to save the game, this is saved to file
# So the save file refers to the time the checkpoint was hit
var SavedStateJSON = ""

################################################################################
##    SETUP
## =============================================================================

# === Internal variables
# Gamepad:
var HasGamepad = false
var GamepadID = null

# A dialog not necessarily prevents other user interaction
# If other interation is to be prevented, InDialogFreeze also has to be true
var InDialog = false
var InDialogFreeze = false
# True while transitioning from one message to the next
var InDialogTransition = false
# Stores the current dialog text array
var CurrentDialogText = []
# Tracks the message ID in multimessage dialogs
var DialogMessageIndex = 0

# Indicates if the tracking effect is on
var InTracking = false

# Indicates if we are in the middle of an interactive level loading
var LoadingLevel = false
var LevelLoader = null

# Initialization
func _ready():
	# === GAMEPADS
	Input.connect("joy_connection_changed", self, "RecheckGamepad")
	RecheckGamepad(null, null)
	
func RecheckGamepad(_device, _connected):
	# Called when a gamepad presence changes
	# Currently we ignore which device is being notified,
	# since we are only interested in knowing if we have one or not
	
	# Retrieve list of available gamepads
	var joylist = Input.get_connected_joypads()
	# If the list is not empty, we have a gamepad
	# currently this game defaults to first gamepad in the list
	if joylist.size() > 0:
		HasGamepad = true
		GamepadID = joylist[0]
	else:
		HasGamepad= false
		GamepadID = null


################################################################################
##    LOAD / SAVE GAME
## =============================================================================

# Operations are split in 2 methods:
#   - one method handles game data <--> JSON string
#   - one method handles JSON string <--> storage
# This separation makes it compatible to storing in other places apart from 
# a local file, should this be implemented in the future

func LoadFromJSON(data):
	# Loads saved data from a JSON string
	
	# Decode JSON into a dictionary
	var data_dict = JSON.parse(data).result
	
	# Check result type. Successful decoding results in dictionary
	if not (data_dict is Dictionary):
		# An error has occurred
		print("Error loading data")
		return false
			
	# Extract data to variables
	CurrentLevel = int(data_dict['level'])
	HasDoubleJump = bool(data_dict['doublejump'])
	TrackingDuration = float(data_dict['tracking'])
	GameTime = max(float(data_dict['time']), 0.0) # avoid value < 0
	ClockVisible = bool(data_dict['clockvisible'])
	PlayerCheckPoint = Vector3(
		float(data_dict['checkpoint'][0]),
		float(data_dict['checkpoint'][1]),
		float(data_dict['checkpoint'][2])
	)
	PlayerCheckPointRotation = float(data_dict['checkpoint'][3])
	RebuildFiredDialogs(data_dict['fired'])
	RebuildTrackedAnimations(data_dict['animations'])


func SaveToJSON():
	# Stores current game state to a JSON string
	
	# Build the data dictionary
	var data_dict = {
		'level': CurrentLevel,
		'doublejump': HasDoubleJump,
		'tracking': TrackingDuration,
		'time': GameTime,
		'clockvisible': ClockVisible,
		'checkpoint': [
			PlayerCheckPoint.x,
			PlayerCheckPoint.y,
			PlayerCheckPoint.z,
			PlayerCheckPointRotation
		],
		'fired': FiredDialogs,
		'animations': TrackedAnimations
	}
	
	# Convert to JSON
	var data = JSON.print(data_dict)
	
	# Finally return converted string
	return data


func LoadGameFromFile():
	# Loads saved file - currently only one save slot is implemented
	# but the file is called "save01.dat" to be compatible to multiple
	# save slots in the future
	print("Loading...")

	# Load JSON string from file
	var file = File.new()
	file.open("user://save01.dat", File.READ)
	var content = file.get_as_text()
	file.close()
	
	# Load game state from JSON
	LoadFromJSON(content)
	
func SaveGameCheckPoint():
	# Saves current game state into the SavedStateJSON variable
	# creating a snapshot of the game to be saved

	SavedStateJSON = SaveToJSON()

func RestoreGameCheckPoint():
	# Restores the game state from the SavedStateJSON
	# into current state
	# WARNING: does not automatically restart level or modify player
	# only modifies internal variables.
	# For "Restart from Checkpoint" effect the level must be reloaded
	
	if SavedStateJSON == "":
		return
	
	LoadFromJSON(SavedStateJSON)

func SaveGameToFile():
	# Stores saved file - currently only one save slot is implemented
	# but the file is called "save01.dat" to be compatible to multiple
	# save slots in the future

	# If SavedStateJSON was not created yet, generate JSON string
	if SavedStateJSON == "":
		SavedStateJSON = SaveToJSON()
		
	# Save JSON to file
	var file = File.new()
	file.open("user://save01.dat", File.WRITE)
	file.store_string(SavedStateJSON)
	file.close()


func RebuildFiredDialogs(fired_data):
	# Conversion to JSON causes all keys in a dictionary to become strings
	# but FiredDialogs uses integer keys, therefore we have to convert
	# all keys back when we load a saved state
	# Also JSON converts all integer values to float, and since our numbers
	# are counters we also have to convert those
	
	# Clear current data
	FiredDialogs.clear()
	
	# Traverse levels in the dictionary coming from JSON
	for level_str in fired_data:
		# Convert level number to int
		var level_number = int(level_str)
		# Create a key for a subdictionary
		FiredDialogs[level_number] = {}
		# Traverse items
		for node_name in fired_data[level_str]:
			# Convert value to integer
			var value = int(fired_data[level_str][node_name])
			# Store in FiredDialogs
			FiredDialogs[level_number][node_name] = value
			
func RebuildTrackedAnimations(anim_data):
	# Conversion to JSON forces all key numbers to strings and
	# all value numbers to floats, but we use level number as key
	# and values in TrackedAnimations must be integers as they are
	# compared to an enum, so we have to traverse all of this
	# forcing a cast
	
	# Clear current data
	TrackedAnimations.clear()
	
	# Traverse levels in the dictionary coming from JSON
	for level_str in anim_data:
		# Convert level number to int
		var level_number = int(level_str)
		# Create a key for a subdictionary
		TrackedAnimations[level_number] = {}
		# Traverse items
		for item_key in anim_data[level_str]:
			# Convert value to integer
			var value = int(anim_data[level_str][item_key])
			# Store in TrackedAnimations
			TrackedAnimations[level_number][item_key] = value
	

func TrackAnimation(item_key):
	# Registers an animation in an AnimationPlayer to be tracked in
	# saved files

	# Check if we did not include this level yetin the list
	if not (CurrentLevel in TrackedAnimations):
		TrackedAnimations[CurrentLevel] = {}
		
	# Check if we are not yet tracking this animation
	if not (item_key in TrackedAnimations[CurrentLevel]):
		# Initialize the value to reset value
		TrackedAnimations[CurrentLevel][item_key] = Utils.ANIM_TRACK_MODE.DoNotTrack

func ClearAnimationTrackStates(anim_player_path):
	# Removes all tracked states from given AnimationPlayer
	# When the same AnimationPlayer has several animations,
	# restoring a checkpoint should only run the last of them
	# so when adding a new one we remove the previous ones
	# In future versions this should be changes to a more clever system
	
	# Assemble the path prefix
	var anim_path_prefix = anim_player_path+';'
	# Traverse tracked animations removing those matching the prefix
	for item_key in TrackedAnimations[CurrentLevel]:
		# If starts with the prefix
		if item_key.begins_with(anim_path_prefix):
			# Clear the item
			TrackedAnimations[CurrentLevel][item_key] = Utils.ANIM_TRACK_MODE.DoNotTrack
	
	
func _on_TrackedAnimation_TrackState(anim_name, anim_player_path, state):
	# Updates a tracked animation marking it as completed/running

	# Check if we did not include this level yetin the list
	if not (CurrentLevel in TrackedAnimations):
		TrackedAnimations[CurrentLevel] = {}

	# Assemble the item string. It is a single string to facilitate
	# checking for its existence in the array
	var item_key = Utils.JoinPlayerAndAnimation(anim_player_path, anim_name)

	# Only proceed if we are tracking this item_key
	# This is important since this same AnimationPlayer may have other
	# untracked animations which will also fire this callback
	if (item_key in TrackedAnimations[CurrentLevel]):
		# Clear any other tracked states from this animation player
		ClearAnimationTrackStates(anim_player_path)
		# Finally, update the value
		TrackedAnimations[CurrentLevel][item_key] = state
		
	

################################################################################
##    GAME STARTUP
## =============================================================================

func NewGame():
	# Resets all variables preparing the game for a new start
	# This method does not fire the game itself
	
	# Reset in-game time clock -> 0.0 means no time elapsed since session start
	GameTime = 0.0
	ClockVisible = false
	# Reset game over flag
	IsGameOver = false
	# Entry level is level 1
	CurrentLevel = 1
	# Player checkpoint resets to origin 
	PlayerCheckPoint = Vector3(0.0, 0.0, 0.0)
	PlayerCheckPointRotation = 0.0 # Y rotation facing north
	# Does not have double jump
	HasDoubleJump = false
	# Tracking duration minimum
	TrackingDuration = 5.0
	# No trigger fired so far
	FiredDialogs.clear()
	# No animations tracked so fat
	TrackedAnimations.clear()
