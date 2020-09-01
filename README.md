# Unpacked_JamVersion

This repository contains the source files of the code base and node tree structure, for the game Unpacked - in its version for Godot Wild Jam #24. 



**Art is not included as it is not open source.** 
*Placeholder models and textures are supplied for compiling and testing. In short: you are free to use the art provided in this repository for internal testing in your projects, but you cannot release a game or any project using them.*


-------------------------------------

Folder structure:

```
Unpacked_JamVersion
  |- Animations       -> Animations used in AnimationPlayer
  |    '- Fox             -> Animations specific for the fox model
  |- Fonts            -> System TTF fonts manually provided for OS consistency (FreeSans used for licensing reasons)
  |- Images           -> Image files
  |    |- Gamepad         -> Images of keyboard/gamepad buttons
  |    |- GWJ             -> Images of GWJ theme/wildcards
  |    |- Textures        -> Images used as texture in meshes
  |    '- UI              -> Images used in the 2D user interface (menus, HUD, etc)
  |- Levels           -> Scene files which are levels (other scene files in Scenes)
  |- Materials        -> Material resource files (not all are used, some are deprecated and were used during development)
  |    '- Scenario        -> Materials for the scenario terrain models
  |- Music            -> Audio files (.ogg) for background music. Placeholder files are included
  |- Scenes           -> Scene files which are not levels (screens, widgets, singletons, etc - level files are in Levels)
  |- Scripts          -> GDScript files
  |- SFX              -> Audio files (.ogg) for sound effects. Placeolder files are included
  |- Shaders          -> Shader files (not all are used, some are deprecated and were used during development)
  _HeightRef.tscn     -> Model as height reference for jumps and double jumps
  
```
