
extends Spatial

#
#  Base for in-game objects
#  Manages persistence
#

onready var persist=get_node("/root/persist")
onready var server=get_node("/root/Server")

var state={}
var props={}

func write(key,value):
	# override on_write, not write
	if on_write(key,value):
		state[key]=value
		persist.flag_unsaved(self)

var _rd_rc_
func read(key):
	# override on_read, not read
	_rd_rc_=on_read(key)
	if _rd_rc_[0]:
		state[key]=_rd_rc_[1]
		return state[key]
	return null

func on_write(key,value):
	# override to process state changes
	return _write_GOB(key,value)

func on_read(key):
	# override to process state queries
	return _read_GOB(key)

func _read_GOB(key):
	if key=="props":
		return [true,props]
	return [false,null]

func _write_GOB(key,value):
	if key=="props":
		props=value
		return true
	return false

func type():
	return "GOB"

func serialize():
	var current={}
	for key in state:
		# run read triggers on serialize
		current[key]=read(key)
	return current.to_json()

func deserialize(data):
	state={}
	for each in data:
		# run write triggers on deserialize
		write(each,data[each])

func _ready():
	pass

func _spawn_GOB():
	write("props",{})

func _spawn():
	_spawn_GOB()
