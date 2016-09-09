
extends Node

signal StopWatch(label)
signal SongChanged(song)

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
var gob_proxy={
	'Account'		:	load("AccountProxy.tscn")
}

# reference to the object lobby
onready var lobby=get_node("/root/lobby")

# game object directory
onready var index=get_node("/root/Peer/index")
var index_bytype={}

# private (client) objects
var resources={}
onready var bgm=get_node("/root/Peer/bgm")
onready var login_timer=get_node("/root/Peer/LoginTimer")
onready var hud=get_node("/root/Peer/View2D/HUD")
onready var dlgLogin=hud.get_node("Login")
onready var dlgAuth=hud.get_node("LoginStatus")
onready var dlgMotd=hud.get_node("motd_bg")
onready var motd=dlgMotd.get_node("motd")
var userAcct=null

func init_client_resources():
	resources['bgm/lobby']=load("user://bgm/lobby.ogg")
	resources['bgm/menu']=load("user://bgm/menu.ogg")

func populate_index():
	var types=index.get_children()
	for each in types:
		index_bytype[each.get_name()]=each

func onConnect():
	window_status("Lobby")
	dlgLogin.nologin(false)
	dlgMotd.set_hidden(false)
	client_id=get_tree().get_network_unique_id()
	client=CHost.instance()
	client.connect("MOTD",self,"onChangeMOTD")
	client.connect("LoginOK",self,"onLoginOK")
	client.connect("LoginFail",self,"onLoginFail")
	client.set_name(str(client_id))
	lobby.add_child(client)
	server.hello(client_id)
	print("connected (id=%d)." % client_id)

func onChangeMOTD(msg):
	motd.set_bbcode(msg)

func fade_quit():
	if segue_cur!=null:
		change_bgm()
		yield(self,"SongChanged")
	get_tree().quit()

func _notification(what):
	if what==MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		fade_quit()

func onConnFail():
	change_bgm(resources['bgm/lobby'])
	window_status("Failed to Connect")
	dlgLogin.hide()
	dlgMotd.hide()
	dlgAuth.set_hidden(false)
	dlgAuth.set_caption("Server is Down")
	dlgAuth.set_message("Please try again later.\n")
	dlgAuth.set_dismiss(true,"Quit")
	yield(dlgAuth,"Dismiss")
	fade_quit()

func onDisconnect():
	userAcct=null
	login_timer.stop()
	clear_gobs()
	server.queue_free()
	client.queue_free()
	get_tree().set_network_peer(null)
	window_status("Disconnected")
	change_bgm(resources['bgm/lobby'])
	dlgLogin.hide()
	dlgMotd.hide()
	dlgAuth.set_hidden(false)
	dlgAuth.set_caption("Server Disconnected")
	dlgAuth.set_message("Please try again later.")
	dlgAuth.set_dismiss(true,"Quit")
	yield(dlgAuth,"Dismiss")
	fade_quit()

export var segue_rate=0.5
var segue=null
var segue_cur=null
var segue_pos=0
var fullscreen=false
var debounce_F11
var elapsed=0
var flags={}
func _process(delta):
	elapsed+=delta

	#####################
	#  BGM transitions  #
	#####################
	if segue==segue_cur:
		segue=null
	if segue!=null:
		if segue_cur==null:
			segue_cur=segue
			if segue_cur==bgm_silence:
				segue_cur=null
			segue=null
			segue_pos=0
			bgm.set_stream(segue_cur)
			if segue_cur!=null:
				bgm.set_volume(1.0)
				bgm.play()
				bgm.set_loop(true)
			emit_signal("SongChanged",segue_cur)
		else:
			if segue_pos>=segue_rate:
				segue_cur=segue
				if segue_cur==bgm_silence:
					segue_cur=null
				segue=null
				segue_pos=0
				bgm.set_stream(segue_cur)
				if segue_cur!=null:
					bgm.set_volume(1.0)
					bgm.play()
					bgm.set_loop(true)
				emit_signal("SongChanged",segue_cur)
			else:
				var vol=1.0-(min(segue_pos,1.5)/segue_rate)
				bgm.set_volume(vol)
				segue_pos+=delta

	#######################
	#  Toggle fullscreen  #
	#######################
	if Input.is_action_pressed("fullscreen_toggle") and !debounce_F11:
			debounce_F11=true
			fullscreen=!fullscreen
			OS.set_window_fullscreen(fullscreen)
	if !Input.is_action_pressed("fullscreen_toggle") and debounce_F11:
		debounce_F11=false

var req_user
func requestLogin(username,password):
	req_user=username
	window_status("Log on %s" % username)
	dlgLogin.hide()
	dlgMotd.hide()
	dlgAuth.show()
	dlgAuth.set_dismiss(false)
	dlgAuth.set_caption("Account Login")
	dlgAuth.set_message("Logging in as %s..." % username)
	server.request_login(client_id,username,password)
	login_timer.set_one_shot(true)
	login_timer.set_wait_time(30)
	login_timer.connect("timeout",client,"login_response",[1,-1])
	login_timer.start()

func onLoginFail(code,why):
	dlgAuth.set_caption("Account Login Failure")
	dlgAuth.set_message(why)
	dlgAuth.set_dismiss(true,"Okay")
	yield(dlgAuth,"Dismiss")
	dlgAuth.hide()
	dlgMotd.show()
	dlgLogin.show()

func onLoginOK(acctID):
	change_bgm(resources['bgm/menu'])
	yield(self,"SongChanged")
	window_status(" %s (logged in)" % req_user)
	dlgAuth.hide()
	userAcct=gob_proxy['Account'].instance()
	userAcct.set_name(acctID)
	userAcct.set_peer(client_id)
	index_bytype['Account'].add_child(userAcct)
	userAcct.read("props")
	yield(userAcct,"notify_props")
	print("userAcct: props=%s" % str(userAcct.attrs['props']))

var bgm_silence=AudioStreamOGGVorbis.new()
func change_bgm(song=null):
	if song!=null:
		segue=song
	else:
		segue=bgm_silence

func onNewSong(s):
	if s!=null:
		print("bgm changed to: %s" % s.get_path())
	else:
		print("bgm silenced")

func _ready():
	populate_index()
	window_status()
	init_client_resources()

	get_tree().connect("connected_to_server",self,"onConnect")
	get_tree().connect("connection_failed",self,"onConnFail")
	get_tree().connect("server_disconnected",self,"onDisconnect")

	connect("SongChanged",self,"onNewSong")
	change_bgm(resources['bgm/lobby'])

	server=SProxy.instance()
	server.set_name(str(SERVER_ID))
	lobby.add_child(server)
	upstream=NetworkedMultiplayerENet.new()
	window_status("Connecting")
	dlgLogin.nologin(true)
	upstream.create_client(server_addr,server_port)
	get_tree().set_network_peer(upstream)
	dlgAuth.hide()
	dlgMotd.hide()
	dlgLogin.set_hidden(false)

	set_process(true)
	get_tree().set_auto_accept_quit(false)

func window_status(msg=""):
	var title=GameName
	if msg!="":
		title+=": %s" % msg
	OS.set_window_title(title)

func clear_gobs():
	for group in index_bytype.keys():
		var childs=index_bytype[group].get_children()
		for each in childs:
			each.queue_free()
