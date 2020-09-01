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

# Shows or hides content based on player presence
# If the player starts a level inside a LODGroup
# the body_entered signal also fires automatically

func _ready():
	# Starting state is hidden
	hide()

func _on_LODGroup_body_entered(body):
	# Shows objects
	
	# If fired by any other body (not Player), abort
	if body.name != 'Player':
		return
	
	# Show all contents at once
	# Animations not used since LOD has to be procedding-time friendly
	show()


func _on_LODGroup_body_exited(body):
	# Hides objects

	# If fired by any other body (not Player), abort
	if body.name != 'Player':
		return

	# Hides all contents at once
	# Animations not used since LOD has to be procedding-time friendly
	hide()

