
extends Node2D

#
#  Base for in-game objects
#  Manages persistence
#
onready var persist=get_node("/root/persist")
onready var server=get_node("/root/Server")

var guid=null

func type():
	return "GOB"

func _ready():
	pass

