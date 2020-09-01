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

# Fires the sniffing/tracking mechanic, applying visual effects and
# highlighting one specific mesh (or more). 
# It is similar to NarratorTrigger (read that one first)
# 
# Meshes must be MeshInstance and must be placed as children of 
# the "TrackPoint/Tracking" node. The materials in those meshes will
# be ignored as they will be replaced by the material from this trigger.
# However, the same material is usually used in Unpacked to allow better
# scene visualization in the editor.
# The material is set in the ScentMaterial, and it must be a shader with
# a uniform float called modulate_effect. This uniform will be animated as:
#     0.0 -> 1.0 when effect triggers
#     1.0 -> 0.0 when effect vanishes
# 
# If designing your own ScentMaterial, make it entirely based on EMISSION
# since the environment animation will most likely render the ALBEDO useless


# Signals parent if this TrackPoint is available or not
# Available means it will trigger when pressing Q
signal Available(sender, state)

# Enable flag used by animations to control when
# this trackpoint can be used
export(bool) var Enabled = true


# "Q" icon mesh
onready var Hint = get_node("Hint")

# Animation controller
onready var Anim = get_node("AnimationPlayer")


var IsActive = false

export(Material) var ScentMaterial

func _ready():
	# Hide the Q icon
	Hint.hide()
	
	# Make this material unique
	ScentMaterial = ScentMaterial.duplicate()
	
	# === Set material for all meshes in "Tracking" subnode:
	
	var mesh_pool = get_node("Tracking")
	# Only do this if we have a Tracking subnode
	if mesh_pool != null:
		var mesh_list = mesh_pool.get_children()
		# Only proceed if the Tracking subnode has content
		if mesh_list.size() > 0:
			
			# Traverse MeshInstances
			for mesh_instance in mesh_list:
				# Only work on MeshInstance nodes
				if mesh_instance is MeshInstance:
						# Make this instance mesh unique
						mesh_instance.mesh = mesh_instance.mesh.duplicate()
						# Set the material
						mesh_instance.mesh.surface_set_material(0, ScentMaterial)
	
	# Set material to reset state
	ScentMaterial.set_shader_param("modulate_effect", 0.0)

	# === Connect Available signal
	
	# The correct practice is usually to emit signals from children
	# connecting them to parent. But on this particular case, we want
	# to have a general purpose trigger object which can be cloned at
	# will, connecting itself to parent passing self as argument
	# This significantly reduces the work and avoids situations in which
	# script recompilation disconnects signals in the levels, so adhering
	# to standard practice does not justify the extra effort on this case
	
	# (As a cool side effect, this will also avoid triggering if
	# the player starts the level inside the trigger)
	
	# Wait an idle frame to make sure the Main object is properly set
	yield(get_tree(), "idle_frame")
	
	# Get the Main object
	var main = get_node("/root/Main")
	
	# Connect "Available" signal to Main object
	var _error = connect("Available", main, "_on_TrackPoint_Available")

func _on_TrackPoint_area_entered(area):
	# If the collision is not with player, abort
	if area.name != "PlayerInteraction":
		return
	
	# Only show hint if enabled:
	if Enabled:
		Hint.show()
	# But always notify Main of player presence
	emit_signal("Available", self, true)


func _on_TrackPoint_area_exited(area):
	# If the collision is not with player, abort
	if area.name != "PlayerInteraction":
		return
	
	Hint.hide()
	emit_signal("Available", self, false)

# ==============================================================================
# Tracking effect


func ToggleEffect(enabled):
	# Toggles the effects used in the sniffing/tracking mechanic
	
	# Turn effects on:
	if enabled and (not IsActive):
		Anim.play("TrackShow")
		
	# Restore normal appearance
	else:
		Anim.play("TrackHide")

	IsActive = enabled
