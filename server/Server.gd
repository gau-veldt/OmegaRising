
extends Node

signal protoCommand(host,data)
signal peerMessage(frame)

var serverVersion=[0,0,1,"prealpha"]
var sendSize=4096
var serverPort=4000
var worldTime=0
# 24 min is one game day idle
var idle_timeout=1440

var udp=PacketPeerUDP.new()

onready var persist=get_node("/root/persist")
onready var serverLog=get_node("Tabber/Log")
onready var quitDlg=get_node("QuitQuestion")
onready var host=TCP_Server.new()
onready var active=get_node("sessions")
var xcvr=load("res://Transceiver.tscn")

var sessionState={}
var frameSession={}

const EOL=RawArray([13,10])
const NUL=RawArray([0])

func versionString():
	return "%d.%d.%03d-%s" % serverVersion

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
	var logfile=File.new()
	logfile.open("user://serverlog",File.WRITE)
	logfile.store_string("%s\n" % serverLog.get_text())
	logfile.close()
	get_tree().quit()

func onConfirmQuit():
	get_node("QuitQuestion").call_deferred("popup")

func _notification(what):
	if (what==MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		onConfirmQuit()

func pluralAppend(qty):
	return ["s","","s"][min(max(0,qty),2)]

var manifest={}
var buffer

func onRecv(peer,data):
	var ss=sessionState[peer]
	ss['idle']=0.0
	ss['ichp']=10.0
	ss['recv']+=data.get_string_from_utf8()
	if ss['mode']=='CMD':
		var data=ss['recv']
		var cmd=""
		var lfPos=data.find("\n")
		while lfPos>0:
			while lfPos==1:
				data=data.right(1+lfPos)
			if lfPos>0:
				cmd=data.left(lfPos-1)
				data=data.right(1+lfPos)
				lfPos=data.find("\n")
			sessionState[peer]['recv']=data
			lfPos=data.find("\n")
			if cmd!="":
				emit_signal("protoCommand",peer,cmd)
				cmd=""

func onSendCompleted(peer):
	var ss=sessionState[peer]

func onDisconnect(peer):
	# remove dropped connections
	var ss=sessionState[peer]
	var sxcvr=ss['xcvr']
	logMessage("[signal] Client %s:%s disconnected." % [ss['addr'],ss['port']])
	sxcvr.detach()
	sxcvr.queue_free()
	sessionState.erase(peer)

var frame={}
func _process(delta):
	# update world time
	worldTime+=delta
	if worldTime>=1440:
		worldTime-=1440

	# update client idles
	var gonzo=[]
	for each in frameSession:
		frameSession[each]['idle']+=delta
		if frameSession[each]['idle']>idle_timeout:
			gonzo.append(each)
	for each in gonzo:
		frameSession.erase(each)
		logMessage("Client id %d punted: idle over %d seconds." % [each,idle_timeout])

	while udp.get_available_packet_count()>0:
		frame.clear()
		frame['data']=udp.get_var()
		frame['addr']=udp.get_packet_ip()
		frame['port']=udp.get_packet_port()
		emit_signal("peerMessage",frame)

	# connect a client
	var ss
	if host.is_connection_available():
		var sess=host.take_connection()
		sessionState[sess]={}
		ss=sessionState[sess]
		ss['addr']=sess.get_connected_host()
		ss['port']=sess.get_connected_port()
		ss['idle']=0.0
		ss['ichp']=10.0
		ss['blk_todo']=0
		ss['blk_done']=0
		ss['recv']=""
		ss['mode']="CMD"
		ss['xcvr']=xcvr.instance()
		active.add_child(ss['xcvr'])
		ss['xcvr'].connect("Disconnected",self,"onDisconnect")
		ss['xcvr'].connect("GotData",self,"onRecv")
		ss['xcvr'].connect("SendingFinished",self,"onSendCompleted")
		ss['xcvr'].attach(sess)
		logMessage("Client %s:%s connected." % [ss['addr'],ss['port']])

	# read any data from connectees
	# and drop disconnected clients
	var fh
	var buf
	var bufsize
	var blknum
	var blkcnt
	var tstr
	for peer in sessionState:
		ss=sessionState[peer]

		if ss['mode']=='SEND':
			bufsize=min(sendSize,ss['blk_todo'])
			blknum=int(ss['blk_done']/sendSize)
			blkcnt=int((ss['blk_todo']+ss['blk_done']+sendSize)/sendSize)
			fh=ss['blk_file']
			buf=fh.get_buffer(bufsize)
			tstr="DATA %06d/%06d %05d " % [blknum,blkcnt-1,bufsize]
			ss['xcvr'].writestr(tstr)
			ss['xcvr'].write(buf)
			ss['xcvr'].write(EOL)
			ss['blk_todo']-=bufsize
			ss['blk_done']+=bufsize
			if ss['blk_todo']==0:
				fh.close()
				ss['blk_file']=null
				ss['blk_todo']=0
				ss['blk_done']=0
				ss['idle']=0.0
				ss['ichp']=10.0
				ss['mode']='CMD'
			
		if ss['mode']=='CMD':
			ss['idle']+=delta
			ss['ichp']-=delta
			if ss['ichp']<=0.0:
				ss['ichp']=10.0		# reset idle checkpoint
				logMessage("%s:%s send keepalive" % [ss['addr'],ss['port']])
				ss['xcvr'].write(NUL)

	persist.save()

onready var acctList=get_node("Tabber/Account/scroll/AcctEntries")
func onAcctAction(act):
	if act==0:			#add
		var entry=HBoxContainer.new()
		var leUser=LineEdit.new()
		var lePass=LineEdit.new()
		entry.set_hidden(false)
		leUser.set_hidden(false)
		lePass.set_hidden(false)
		var lineNo=1+acctList.get_children().size()
		entry.set_name("acct%d" % lineNo)
		leUser.set_custom_minimum_size(Vector2(100,0))
		lePass.set_custom_minimum_size(Vector2(100,0))
		leUser.set_text("user%d" % lineNo)
		lePass.set_text("pass%d" % lineNo)
		entry.add_child(leUser)
		entry.add_child(lePass)
		acctList.add_child(entry)

func _ready():
	var quitBtn=quitDlg.get_ok()
	quitBtn.connect("pressed",self,"onStopServer")
	quitBtn.set_text("Quit")
	quitDlg.call_deferred("set_pos",Vector2(482,356))
	get_tree().set_auto_accept_quit(false)

	logMessage("Omega Rising server (Version %s) starting up" % versionString())
	logMessage("Server running via Godot version %s" % "")
	logMessage("Loading asset manifest...")
	manifest.clear()
	var mf=ConfigFile.new()
	mf.load("res://manifest")
	var aCount=mf.get_section_keys("Assets").size()
	logMessage("Game currently has %d asset%s." % [aCount,pluralAppend(aCount)] )
	var info
	for each in mf.get_section_keys("Assets"):
		info=mf.get_value("Assets",each,{})
		manifest[each]=info
	var err=mf.save("res://manifest")
	if err!=OK:
		logMessage("PANIC: Server directory isn't writable")
		onStopServer()

	var cfg=ConfigFile.new()
	var err=cfg.load("user://server.ini")
	sendSize=cfg.get_value("BGDownload","block_size",4096)
	serverPort=cfg.get_value("Server","port",4000)
	cfg.set_value("BGDownload","block_size",sendSize)
	cfg.set_value("Server","port",serverPort)
	err=cfg.save("user://server.ini")
	logMessage("Xfer block size is "+str(sendSize))

	logMessage("Listening on port "+str(serverPort))
	host.listen(serverPort)
	udp.listen(serverPort)
	
	set_process(true)

