
extends "GOB.gd"

var name		# player name
var region		# null for overworld, otherwise names region player is in
var zone		# overworld zone
var phases		# phases mob exists in

func type():
	return "Mob"

func on_read(key):
	return _read_Mob(key)

func on_write(key,value):
	return _write_Mob(key,value)

func _read_Mob(key):
	var baserc=_read_GOB(key)
	if !baserc[0]:
		if key=="name":
			return [true,name]
		if key=="region":
			return [true,region]
		if key=="zone":
			return [true,zone]
		if key=="phases":
			return [true,phases]
		if key=="pos":
			var tr=get_translation()
			return [true,[tr.x,tr.y,tr.z]]
		if key=="rot":
			var rot=get_rotation_deg()
			return [true,[rot.x,rot.y,rot.z]]
		return [false,null]
	else:
		return baserc

func _write_Mob(key,val):
	var baserc=_write_GOB(key,val)
	if !baserc:
		if key=="name":
			name=val
			return true
		if key=="region":
			region=val
			return true
		if key=="zone":
			zone=val
			return true
		if key=="phases":
			phases=val
			return true
		if key=="pos":
			set_translation(Vector3(val[0],val[1],val[2]))
			return true
		if key=="rot":
			set_rotation_deg(Vector3(val[0],val[1],val[2]))
			return true
		return false
	else:
		return baserc

func _ready():
	pass

func _spawn_Mob():
	_spawn_GOB()
	write("name","NoName")
	write("region",null)
	write("zone","overworld")
	write("phases",{})
	write("pos",[0,0,0])
	write("rot",[0,0,0])

func _spawn():
	_spawn_Mob()
