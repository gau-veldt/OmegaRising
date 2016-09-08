
extends Node

onready var server=get_node("/root/Peer")
onready var persist=get_node("/root/persist")

#	server's RPC endpoint
#		- net_id=1
#		- lives in /root/lobby
#		- name==str(net_id)=="1"
#
#	At each client a ServerProxy object is placed under /root/lobby/
#	nodepath with name==str(net_id_of_server)=="1" (server is always
#   net_id 1).  Calls by the client into this ServerProxy object
#   become an rpc call received by the server at its ServerNode object.
#

remote func hello(id):
	server.logMessage("got client %d hello" % id)

const LOGIN_OK			=0
const LOGIN_INVALID		=1
const LOGIN_BADACCT		=2
const LOGIN_REFUSED		=3
const LOGIN_SERVERR		=4
var login_responders={}
remote func insecure_login(id,username,passwd):
	if !login_responders.has(id):
		var code=LOGIN_INVALID
		var acct=null
		var client=get_node("/root/lobby/%d" % id)
		var accts=persist.get_gob_index('Account').get_children()
		var phash=(server.serverSalt+passwd).sha256_text()
		var tm=Timer.new()
		self.add_child(tm)
		tm.set_name("login_responder_%d" % id)
		login_responders[id]=tm
		tm.set_wait_time(5)
		tm.set_one_shot(true)
		tm.start()
		for each in accts:
			var auser=each.read("username")
			var apass=each.read("password")
			if auser==username and apass==phash:
				code=LOGIN_OK
				acct=each
				acct._set_owner(id)
				break
		tm.connect("timeout",client,"login_response",[code,self,acct])

func login_cleanup(id):
	self.remove_child(login_responders[id])
	login_responders.erase(id)

func _ready():
	pass

