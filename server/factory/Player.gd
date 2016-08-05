
extends "GOB.gd"

var name

func type():
	return "Player"

func on_read(key):
	if key=="name":
		return [true,name]
	return [false,null]

func on_write(key,val):
	if key=="name":
		name=val
		return true
	return false

func _ready():
	write("name","NoName")
