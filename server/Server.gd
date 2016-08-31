
extends Node

var serverVersion=[0,1,0,"pre_alpha"]
var sendSize=4096
var serverPort=4000
var serverSalt='@@@@@@@@'
var worldTime=0
var Godot_Version=OS.get_engine_version()
# 24 min is one game day idle
var idle_timeout=1440

var host=NetworkedMultiplayerENet.new()

onready var persist=get_node("/root/persist")
onready var serverLog=get_node("Tabber/Log")
onready var quitDlg=get_node("QuitQuestion")
onready var active=get_node("/root/lobby")
onready var server_node=load("res://ServerNode.tscn")
var server_iface=null
var manifest={}

func versionString():
	return "%d.%d.%03d-%s" % serverVersion

var _ascii=RawArray(range(33,127)).get_string_from_ascii()
func rand_str(sz):
	var rslt=""
	for ch in range(sz):
		rslt+=_ascii[int(rand_range(0,94))]
	return rslt

func logMessage(msg):
	var now=OS.get_time()
	var buf=serverLog.get_text()
	buf+="[%08x:%03d] " % [OS.get_unix_time(),OS.get_ticks_msec()%1000]
	buf+=msg+"\n"
	serverLog.set_text(buf)
	serverLog.cursor_set_line(serverLog.get_line_count())

var menuDispatch={
	"Server": {
		0: [".","onConfirmQuit"],
	},
}

func onServerMenuItem(id):
	var n=get_node(menuDispatch["Server"][id][0])
	var proc=menuDispatch["Server"][id][1]
	n.call(proc)

func onStopServer():
	logMessage("Server shutting down.")
	server_iface.queue_free()
	var logfile=File.new()
	logfile.open("user://serverlog",File.WRITE)
	logfile.store_string("%s\n" % serverLog.get_text())
	logfile.close()
	get_tree().set_network_peer(null)
	get_tree().quit()

func onConfirmQuit():
	get_node("QuitQuestion").call_deferred("popup")

func _notification(what):
	if (what==MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		onConfirmQuit()

func pluralAppend(qty):
	return ["s","","s"][min(max(0,qty),2)]

onready var acctCtl=get_node("Tabber/Account")
var oldAcctCount=-1
var curAcctCount

onready var acct_idx=persist.get_gob_index('Account')
func _process(delta):
	# update world time
	worldTime+=delta
	if worldTime>=1440:
		worldTime-=1440

	# update server account view
	curAcctCount=acct_idx.get_children().size()
	if curAcctCount!=oldAcctCount:
		acctCtl.refresh(acct_idx)
		oldAcctCount=curAcctCount

	persist.save()

var lobby={}
onready var CProxy=load("res://ClientProxy.tscn")
func onClientConnect(id):
	var pxy=CProxy.instance()
	lobby[id]=pxy
	pxy.set_name(str(id))
	pxy._set_id(id)
	active.add_child(pxy)
	pxy.hello()
	logMessage("Client %d connected" % id)

func onClientDrop(id):
	var pxy=lobby[id]
	lobby.erase(id)
	pxy.queue_free()
	logMessage("Client %d disconnected" % id)

func _ready():
	var quitBtn=quitDlg.get_ok()
	quitBtn.connect("pressed",self,"onStopServer")
	quitBtn.set_text("Quit")
	quitDlg.call_deferred("set_pos",Vector2(482,356))
	get_tree().set_auto_accept_quit(false)

	logMessage("Omega Rising server (Version %s) starting up" % versionString())
	logMessage("Server running via Godot version %s" % OS.get_engine_version()['string'])
	logMessage("Loading asset manifest...")
	manifest.clear()
	var mf=ConfigFile.new()
	mf.load("user://manifest")
	var aCount=mf.get_section_keys("Assets").size()
	logMessage("Game currently has %d asset%s." % [aCount,pluralAppend(aCount)] )
	var info
	for each in mf.get_section_keys("Assets"):
		info=mf.get_value("Assets",each,{})
		manifest[each]=info
	var err=mf.save("user://manifest")
	if err!=OK:
		logMessage("PANIC: Server directory isn't writable")
		onStopServer()

	var cfg=ConfigFile.new()
	var err=cfg.load("user://server.ini")
	serverPort=cfg.get_value("Server","port",4000)
	serverSalt=cfg.get_value("Server","salt",rand_str(8))
	cfg.set_value("Server","port",serverPort)
	cfg.set_value("Server","salt",serverSalt)
	err=cfg.save("user://server.ini")

	server_iface=server_node.instance()
	server_iface.set_name(str(1))
	active.add_child(server_iface)
	logMessage("Server RPC endpoint ready.")

	logMessage("Listening on port "+str(serverPort))
	host.create_server(serverPort,100)
	get_tree().set_network_peer(host)
	get_tree().connect("network_peer_connected",self,"onClientConnect")
	get_tree().connect("network_peer_disconnected",self,"onClientDrop")

	set_process(true)

