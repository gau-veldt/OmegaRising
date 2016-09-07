
extends Node

var net_id=1

func hello(cid):
	# send hello ("Client is ready")
	rpc_id(1,"hello",cid)

func request_login(cid,username,passwd):
	rpc_id(1,"insecure_login",cid,username,passwd)

func _ready():
	pass

