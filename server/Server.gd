
extends Node

var serverVersion=[0,1,0,"pre_alpha"]
var serverPort=4000
var serverSalt='@@@@@@@@'
var worldTime=0
var Godot_Version=OS.get_engine_version()
var motd=""
# 24 min is one game day idle
var idle_timeout=1440

var host=NetworkedMultiplayerENet.new()

onready var persist=get_node("/root/persist")
onready var uiRoot=get_node("Tabber")
onready var serverLog=get_node("Tabber/Log")
onready var quitDlg=get_node("QuitQuestion")
onready var active=get_node("/root/lobby")
onready var server_node=load("res://ServerNode.tscn")
var server_iface=null

func versionString():
	return "%d.%d.%03d-%s" % serverVersion

var _ascii=RawArray(range(33,127)).get_string_from_ascii()
func rand_str(sz):
	var rslt=""
	for ch in range(sz):
		rslt+=_ascii[int(rand_range(0,94))]
	return rslt

var preLog=null
func logMessage(msg):
	var now=OS.get_time()
	var buf
	if serverLog:
		buf=serverLog.get_text()
		if preLog!=null:
			buf+=preLog
			preLog=null
		buf+="[%08x:%03d] " % [OS.get_unix_time(),OS.get_ticks_msec()%1000]
		buf+=msg+"\n"
		serverLog.set_text(buf)
		serverLog.cursor_set_line(serverLog.get_line_count())
	else:
		if preLog==null: preLog=""
		buf="[%08x:%03d] " % [OS.get_unix_time(),OS.get_ticks_msec()%1000]
		buf+=msg+"\n"
		preLog+=buf

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
var _hideUI_debounce=false
var _hideUI=false
func _process(delta):
	# update world time
	worldTime+=delta
	if worldTime>=1440:
		worldTime-=1440

	# UI hide toggle (allows viewing world)
	if Input.is_action_pressed("hide_ui_toggle") and !_hideUI_debounce:
			_hideUI_debounce=true
			_hideUI=!_hideUI
			ToggleUI(_hideUI)
	if !Input.is_action_pressed("hide_ui_toggle") and _hideUI_debounce:
		_hideUI_debounce=false
	if GodCam!=null:
		MoveGodCam(delta)

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
	pxy.motd(motd)
	logMessage("Client %d connected" % id)

func onClientDrop(id):
	logout_on_drop(id)
	var pxy=lobby[id]
	lobby.erase(id)
	pxy.queue_free()
	logMessage("Client %d disconnected" % id)

func _ready():
	var err
	var quitBtn=quitDlg.get_ok()
	quitBtn.connect("pressed",self,"onStopServer")
	quitBtn.set_text("Quit")
	quitDlg.call_deferred("set_pos",Vector2(482,356))
	get_tree().set_auto_accept_quit(false)

	logMessage("Omega Rising server (Version %s) starting up" % versionString())
	logMessage("Server running via Godot version %s" % OS.get_engine_version()['string'])

	var motdF=File.new()
	err=motdF.open("user://motd",File.READ)
	if err==OK:
		motd=motdF.get_as_text()
		motdF.close()
		logMessage("Read server MOTD (%d chars)" % motd.length())

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

func logout_on_drop(id):
	var accts=acct_idx.get_children()
	for each in accts:
		if each._is_owner(id):
			each.logout()
			var handle=each.read("handle")
			var user=each.read("username")
			logMessage("%s@%s logged out due to dropped client %d." % [handle,user,id])

var hooks={}
func has_hook(name):
	return hooks.has(name)
func set_hook(name,ob,method):
	hooks[name]={'node':ob,'method':method}
	print("hook %s set to [%s].%s" % [name,ob.get_name(),method])
func remove_hook(name):
	if hooks.has(name):
		hooks.erase(name)
func call_hook(name,arglist):
	if hooks.has(name):
		var hook=hooks[name]
		print("call hook %s" % name)
		hook['node'].callv(hook['method'],arglist)

var GodCam=null
var GodPos=Vector3(0,1.5,4)
var GodRot=Vector3(0,0,0)
onready var env=get_node("env")
func ToggleUI(hide):
	uiRoot.set_hidden(hide)
	if hide:
		if GodCam==null:
			var lig=OmniLight.new()
			lig.set_color(Light.COLOR_DIFFUSE,Color(.75,.75,.75))
			lig.set_color(Light.COLOR_SPECULAR,Color(1,1,1))
			lig.set_parameter(Light.PARAM_RADIUS,8)
			lig.set_parameter(Light.PARAM_ENERGY,1)
			GodCam=Camera.new()
			GodCam.add_child(lig)
			add_child(GodCam)
			GodCam.set_translation(GodPos)
			GodCam.set_rotation(GodRot)
			GodCam.make_current()
	else:
		if GodCam!=null:
			GodCam.queue_free()
			GodCam=null

const rotSpd=90
const movSpd=1
const r2deg=180.0/PI
const deg2r=PI/180.0
func MoveGodCam(scale):
	var updn=0
	var hdg=0
	if Input.is_action_pressed("godcam_lup"):
		updn=-deg2r*rotSpd*scale
	if Input.is_action_pressed("godcam_ldn"):
		updn=deg2r*rotSpd*scale
	if Input.is_action_pressed("godcam_lt"):
		hdg=-deg2r*rotSpd*scale
	if Input.is_action_pressed("godcam_rt"):
		hdg=deg2r*rotSpd*scale
	GodCam.rotate_x(updn)
	GodCam.rotate_y(hdg)
	GodRot=GodCam.get_rotation()
	var mov=Vector3(0,0,0)
	if Input.is_action_pressed("godcam_frwd"):
		mov.z=-1
	if Input.is_action_pressed("godcam_rvrs"):
		mov.z=1
	GodCam.translate(mov*movSpd*scale)
	GodPos=GodCam.get_translation()

