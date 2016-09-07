
extends Node

var net_id
func _set_id(id):
	net_id=id

#
#	Proxy for connected client
#	The server adds one under /root/lobby/ nodepath
#   whenever a client is connected and the object is
#	named with client's net_id.
#
#	server makes rpc calls on these objects to provide information
#	or notifications to a particular client via:
#	get_node("/root/lobby/%s" % net_id).rpc_id(net_id,...)
#
#   At the client the rpc is handled by the ClientNode located under client's
#   /root/lobby/ scene tree nodepath
#
#	Remote peer id's should be XxxProxy, local peer id should be XxxNode
#   XxxProxy'ies are only used to target outgoing rpc method calls.
#   Incoming rpc methods are implemented on XxxNode's using remote keyword.
#
#	A server with two clients (1000,1001) connected should look
#	as follows under /root/lobby/:
#
#	server:
#		ServerNode		(name="1")
#		ClientProxy		(name="1000")
#		ClientProxy		(name="1001")
#
#	client 1000:
#		ServerProxy		(name="1")
#		ClientNode		(name="1000")
#		ClientProxy		(name="1001")
#
#	client 1001:
#		ServerProxy		(name="1")
#		ClientProxy		(name="1000")
#		ClientNode		(name="1001")
#

func hello():
	# handshake ("server is ready")
	rpc_id(net_id,"hello",1)

func motd(msg):
	# send MOTD
	rpc_id(net_id,"motd",1,msg)

func login_response(code,srv):
	if code==0:
		srv.server.logMessage("Client %d logged in." % net_id)
	else:
		if code==1:
			srv.server.logMessage("Client %d authentication failure." % net_id)
		else:
			srv.server.logMessage("Client %d login failure (err=%d)." % [net_id,code])
	# login response
	rpc_id(net_id,"login_response",1,code)
	srv.login_cleanup(net_id)

func _ready():
	pass

