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


extends Area

# CheckPoint objects are used to store current progress as the saved state
# When player asks to save the game, the last saved state created by
# a CheckPoint is used, and not real-time data
# Progress is stored by entering the area of a checkpoint
# Optionally it can automatically change level
# It comes with a 2m cylinder collision shape, but if larger area is
# needed, DO NOT SCALE the CheckPoint as it yields weird results
# Instead add more collision shapes to it, as all will contribute

# === Configuration variables for this trigger

# Force saving the checkpoint position instead of actual player position
# This is particularly useful when changing levels
export(bool) var CorrectPosition = false

# Does this checkpoint move to next level?
export(bool) var ChangeLevel = false
# List of levels to select
export(Utils.LEVELS) var Level = Utils.LEVELS.L01_LoosingThePack

func _ready():
	# The correct practice is usually to emit signals from children
	# And handle them on parent. But on this particular case, we want
	# to have a general purpose trigger object which can be cloned at
	# will, connecting itself to parent passing self as argument
	# Standard body_entered signal does not track sender, so adhering
	# to standard practice does not justify the extra effort on this case
	
	# (As a cool side effect, this will also avoid triggering if
	# the player starts the level inside the trigger)
	
	# Wait an idle frame to make sure the Main object is properly set
	yield(get_tree(), "idle_frame")
	
	# Get the Main object
	var main = get_node("/root/Main")
	
	# Connect the body_entered signal passing self as extra argument
	# (the reason we are doing all of this)
	var _error = connect("body_entered", main, "_on_CheckPoint", [self])


