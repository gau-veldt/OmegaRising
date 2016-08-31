
extends Node

var net_id=1

func hello(cid):
	# send hello ("Client is ready")
	rpc_id(1,"hello",cid)

func _ready():
	pass

