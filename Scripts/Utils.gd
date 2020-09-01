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
# This is a singleton used to broadcast the enum constants used in
# export vars, as well as helper functions to join and split animation
# identifiers into/from strings.

# Interaction Areas have a type, which is listed in TRIGGER_TYPE
# Read InteractionArea.gd for more information
enum TRIGGER_TYPE {
	# Dialog areas trigger a simple message, which can freeze controls or not
	Dialog
}

# Narrator triggers can perform extra actions, listed below
# Read NarratorTrigger.gd for more information
enum NARRATOR_ACTION {
	# Does nothing special
	None,
	# Starts the game clock
	StartClock
}

# List of levels
enum LEVELS {
	L01_LoosingThePack = 1,
	L02_LightInTheEndOfTheTunnel = 2,
	L03_LeftToRight = 3,
	L04_HelloDarkness = 4,
	L05_AgainstTheFlow = 5
}

# Possible ways to track an animation
enum ANIM_TRACK_MODE {
	# Not tracking
	DoNotTrack,
	# Track if the animation is completed. Restores moving to last frame
	IsCompleted,
	# Track if animation is running. Restores calling play()
	IsPlaying
}

# List of skills which can be found on the map
enum SKILLS {
	None,
	DoubleJump
}



func JoinPlayerAndAnimation(path, animation_name):
	# Joins the string nodepath of an AnimationPlayer
	# and the animation name together
	return path+';'+animation_name
	
func SplitPlayerAndAnimation(value):
	# Splits a string into an AnimationPlayer nodepath
	# and animation name
	
	# Split the string  by ';' into a PoolStringArray
	var str_array = value.split(';')
	# Return data as a normal array
	return [str_array[0], str_array[1]]
