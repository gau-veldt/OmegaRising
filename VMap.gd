#
#  Virtual TileMap
#
#  Allows very large maps on disk to be paged as quadrants
#  Centered on the player, neighbouring quadrants are loaded
#  to result in 3x3 (9) quadrants loaded at all times.
#
#  As player moves the quadrant centered on the player will be
#  at the edge of the 3x3 loaded map.  The loaded quadrant
#  indices will be adjusted so the player quadrant is once
#  again in the center.  Any now-unloaded cells will then
#  load and quadrants outside the 3x3 quadrant zone are
#  then unloaded.
#
#  Quadrants with no disk chunks will be handled with a suitable
#  dummy tilemap by the load script.
#

extends Node2D

# member variables here, example:
# var a=2
# var b="textvar"

export(float) var lightLevel=0.75
export(float) var lightVariance=0.15

onready var lightNode=get_node("Lighting")

func getLights():
	# returns list of light nodes on map
	return lightNode.get_children()

func enableLights(bEnable):
	lightNode.set_hidden(not bEnable)

func setLightLevel(amt):
	for light in getLights():
		light.lightMax=amt

func setLightVariance(amt):
	for light in getLights():
		light.lightVariance=amt

func setLightColor(clr):
	for light in getLights():
		light.set_color(clr)

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	setLightVariance(.11)
