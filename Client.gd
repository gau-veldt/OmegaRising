
extends Node

# proxy object for server
const SERVER_ID=1
var SProxy=load("ServerProxy.tscn")
var server=null
var upstream=null
var server_addr="127.0.0.1"
var server_port=4000
var CHost=load("ClientHost.tscn")
var client_id=0
var client=null

# reference to the object lobby
onready var lobby=get_node("/root/lobby")

func onConnect():
	client_id=get_tree().get_network_unique_id()
	client=CHost.instance()
	client.set_name(str(client_id))
	lobby.add_child(client)
	server.hello(client_id)
	print("connected (id=%d)." % client_id)

func onConnFail():
	print("connection failed.")
	pass

func onDisconnect():
	server.queue_free()
	client.queue_free()
	get_tree().set_network_peer(null)
	print("disconnected.")

func _process(delta):
	pass

func _ready():
	OS.set_window_title("Omega Rising")

	get_tree().connect("connected_to_server",self,"onConnect")
	get_tree().connect("connection_failed",self,"onConnFail")
	get_tree().connect("server_disconnected",self,"onDisconnect")

	server=SProxy.instance()
	server.set_name(str(SERVER_ID))
	lobby.add_child(server)
	upstream=NetworkedMultiplayerENet.new()
	upstream.create_client(server_addr,server_port)
	get_tree().set_network_peer(upstream)

	set_process(true)

