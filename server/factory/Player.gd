
extends "GOB.gd"

var name		# player name
var region		# null for overworld, otherwise names region player is in

func type():
	return "Player"

func on_read(key):
	if key=="name":
		return [true,name]
	if key=="region":
		return [true,region]
	if key=="pos":
		var tr=get_translation()
		return [true,[tr.x,tr.y,tr.z]]
	if key=="rot":
		var rot=get_rotation_deg()
		return [true,[rot.x,rot.y,rot.z]]
	return [false,null]

func on_write(key,val):
	if key=="name":
		name=val
		return true
	if key=="region":
		region=val
		return true
	if key=="pos":
		set_translation(Vector3(val[0],val[1],val[2]))
		return true
	if key=="rot":
		set_rotation_deg(Vector3(val[0],val[1],val[2]))
		return true
	return false

func _ready():
	write("name","NoName")
	write("region",null)
	write("pos",[0,0,0])
	write("rot",[0,0,0])
