
extends Node

var GameName="Omega Rising"

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

# game object directory
onready var index=get_node("/root/Peer/index")

# private (client) objects
var resources={}
onready var bgm=get_node("/root/Peer/bgm")
onready var hud=get_node("/root/Peer/View2D/HUD")
onready var dlgLogin=hud.get_node("Login")
onready var dlgAuth=hud.get_node("LoginStatus")

func init_client_resources():
	resources['bgm/lobby']=load("user://bgm/lobby.ogg")
	resources['bgm/menu']=load("user://bgm/menu.ogg")

func onConnect():
	window_status("Connected")
	dlgLogin.nologin(false)
	client_id=get_tree().get_network_unique_id()
	client=CHost.instance()
	client.set_name(str(client_id))
	lobby.add_child(client)
	server.hello(client_id)
	print("connected (id=%d)." % client_id)

func onConnFail():
	window_status("Failed to Connect")
	dlgLogin.hide()
	dlgAuth.set_hidden(false)
	dlgAuth.set_caption("Server is Down")
	dlgAuth.set_message("Please try again later.\n")
	dlgAuth.set_dismiss(true,"Quit")
	yield(dlgAuth,"Dismiss")
	get_tree().quit()

func onDisconnect():
	server.queue_free()
	client.queue_free()
	get_tree().set_network_peer(null)
	window_status("Disconnected")
	dlgLogin.hide()
	dlgAuth.set_hidden(false)
	dlgAuth.set_caption("Server Disconnected")
	dlgAuth.set_message("Please try again later.")
	dlgAuth.set_dismiss(true,"Quit")
	yield(dlgAuth,"Dismiss")
	get_tree().quit()

func _process(delta):
	pass

func requestLogin(username,password):
	window_status("Log on %s" % username)
	dlgLogin.hide()
	dlgAuth.show()
	dlgAuth.set_caption("Account Login")
	dlgAuth.set_message("Logging in as %s..." % username)

func _ready():
	window_status()
	init_client_resources()

	get_tree().connect("connected_to_server",self,"onConnect")
	get_tree().connect("connection_failed",self,"onConnFail")
	get_tree().connect("server_disconnected",self,"onDisconnect")

	server=SProxy.instance()
	server.set_name(str(SERVER_ID))
	lobby.add_child(server)
	bgm.set_stream(resources['bgm/lobby'])
	bgm.play()
	upstream=NetworkedMultiplayerENet.new()
	window_status("Connecting")
	dlgLogin.nologin(true)
	upstream.create_client(server_addr,server_port)
	get_tree().set_network_peer(upstream)
	dlgAuth.hide()
	dlgLogin.set_hidden(false)

	set_process(true)

func window_status(msg=""):
	var title=GameName
	if msg!="":
		title+=": %s" % msg
	OS.set_window_title(title)
