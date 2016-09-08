extends Node

var attrs={}
var signals={}

var _peer=null
func set_peer(id):
	_peer=id

func read(key):
	var signame="notify_%s" % key
	if !signals.has(signame):
		add_user_signal(signame)
		signals[signame]=true
	rpc_id(1,"get_attr",_peer,key)
remote func attr_is(from,key,value):
	if from==1:
		var signame="notify_%s" % key
		attrs[key]=value
		emit_signal(signame)

func _ready():
	pass
