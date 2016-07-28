
extends Node

# reference to the object lobby
onready var lobby=get_node("/root/lobby")

onready var server=get_node("Connection")
onready var dir=Directory.new()
onready var bgm=get_node("bgm")
onready var focus=get_node("viewpoint")
onready var camera=focus.get_node("Camera")
onready var userscreen=camera.get_node("Decoration")
onready var hud=camera.get_node("Decoration/HUD")
onready var dlGui=camera.get_node("Decoration/HUD/DL")
onready var timeGui=camera.get_node("Decoration/HUD/Time")
onready var dayAnim=camera.get_node("Decoration/DayNightCycle")
onready var world_over=get_node("Overworld")
onready var world_rgn=get_node("Regional")

var udp=PacketPeerUDP.new()

# asset related vars
var assetManifest={}
const dl_head_size=25
const mfFile="user://manifest"
var svrManifest={}

func loadManifest():
	var md={}
	var mf=File.new()
	if !mf.file_exists(mfFile):
		mf.open(mfFile,File.WRITE)
		mf.store_line({}.to_json())
		mf.close()
	mf.open(mfFile,File.READ)
	md.parse_json(mf.get_line())
	mf.close()
	assetManifest=md

func saveManifest():
	var mf=File.new()
	mf.open(mfFile,File.WRITE)
	mf.store_line(assetManifest.to_json())
	mf.close()

func diffManifest(mfOld,mfNew):
	# generate a patch diff from mfOld to mfNew
	var diff={"+":[],"-":[],"=":[],":":[]}
	# determine assets unchanged, modified or deleted
	for asset in mfOld:
		if mfNew.has(asset):
			if mfNew[asset]["size"]==mfOld[asset]["size"] and \
			   mfNew[asset]["hash"]==mfOld[asset]["hash"]:
				# unchanged
				diff["="].append(asset)
			else:
				# modified
				diff[":"].append(asset)
		else:
			# deleted
			diff["-"].append(asset)

	# determine assets added
	for asset in mfNew:
		if not mfOld.has(asset):
			diff["+"].append(asset)

	return diff

# map related vars
var currentMap=null

func enableLights(enable):
	if currentMap!=null:
		currentMap.enableLights(enable)

func setWorldTime(time):
	# time is [0,1440)
	# 1440 seconds (24 real world minutes) per game day
	# 24-hr 0 is 00:00, 1439 is 23:59
	dayAnim.seek(time)
	# when changing time check that lights are properly on or off
	if time>=390.0 and time<1245.0:
		enableLights(false)
	else:
		enableLights(true)

func initialize_dir(path):
	# creates directory in path if it doesn't exist
	var err
	if not dir.dir_exists(path):
		err=dir.make_dir(path)
		if err!=OK:
			print("Error creating dir ",path,": ",err)
		return err
	else:
		return OK

func leftmost(raw,amt):
	# return new rawarray that is leftmost bytes of raw
	if amt>raw.size():
		amt=raw.size()
	if amt<1:
		amt=0
	raw.resize(amt)
	return raw

func left_delete(raw,amt):
	# deletes amt bytes from beginning of rawarray
	if amt>=raw.size():
		raw.resize(0)
		return raw
	if amt<=0:
		# nothing to do
		return raw
	#
	# *** THIS IS A HACK ***
	# We need a subarray (slice) operation to do this properly
	# This hack will copy the entire data three times!!! O(N)
	# as RawArray's copy when modified.
	# Alas this hack is still faster than scriptlooping to
	# left-delete using .remove() and having the data copied on
	# each pass through the loop! O(N^2+N) (for a mere 10 KB
	# of data scriptlooping results in 50 MB!!! of wasted copying,
	# whereas this hack only copies 30K)
	#
	raw.invert()
	raw.resize(raw.size()-amt)
	raw.invert()
	return raw

func find_in_raw(haystack,needle):
	for i in range(haystack.size()):
		if haystack[i]==needle:
			return i
	return -1

var serverExpect=[]
var serverFIFO=RawArray()

const lineExpectors=["manifest","time"]

var ordRaw=RawArray([0])
var serverParse=""
var intExpect=0
var fh
var blk_cur
var blk_cur_size
var blk_total
var blk_data_done
var blk_data_total
var blk_data=RawArray()
func onRecv(srvr,data):
	serverFIFO.append_array(data)
	var expecting=serverExpect[0]

	var scanning=true
	var success
	while scanning:
		success=0
		if expecting in lineExpectors:
			# results types expecting a string
			var where=find_in_raw(serverFIFO,10)
			if where>0:
				serverParse=""
				for i in range(where+1):
					ordRaw.set(0,serverFIFO[i])
					serverParse+=ordRaw.get_string_from_utf8()
				serverFIFO=left_delete(serverFIFO,where+1)
				processResult(expecting,serverParse)
				expecting=""
				serverExpect.pop_front()
				if serverExpect.size()>0:
					success+=1
					expecting=serverExpect[0]

		if expecting=="head":
			if serverFIFO.size()>=dl_head_size:
				success+=1
				serverExpect.pop_front()
				serverParse=""
				for i in range(dl_head_size):
					ordRaw.set(0,serverFIFO[i])
					serverParse+=ordRaw.get_string_from_ascii()
				serverFIFO=left_delete(serverFIFO,dl_head_size)
				blk_cur=int(serverParse.substr(5,6))
				if blk_cur==0:
					# initial 0% block notification
					onBlockNotify(blk_cur,blk_total,blk_data_done,blk_data_total)
				blk_total=int(serverParse.substr(12,6))
				blk_cur_size=int(serverParse.substr(19,5))
				serverExpect.append(str(blk_cur_size))
				expecting=serverExpect[0]

		intExpect=int(expecting)
		if intExpect>0:
			blk_cur_size=intExpect
			if serverFIFO.size()>=blk_cur_size:
				expecting=""
				serverExpect.pop_front()
				blk_data_done+=blk_cur_size
				blk_data.append_array(leftmost(serverFIFO,blk_cur_size))
				serverFIFO=left_delete(serverFIFO,blk_cur_size)
				onBlockNotify(blk_cur,blk_total,blk_data_done,blk_data_total)
				if blk_cur<blk_total:
					success+=1
					serverExpect.append("blkeol")
					expecting=serverExpect[0]
				else:
					success+=1
					serverExpect.append("lasteol")
					processDownload(blk_data,dlFile)
					blk_data.resize(0)

		if expecting=="blkeol":
			if serverFIFO.size()>=2:
				success+=1
				expecting=""
				serverFIFO=left_delete(serverFIFO,2)
				serverExpect.pop_front()
				serverExpect.append("head")
				expecting=serverExpect[0]

		if expecting=="lasteol":
			if serverFIFO.size()>=2:
				success+=1
				expecting=""
				serverFIFO=left_delete(serverFIFO,2)
				serverExpect.pop_front()
				if serverExpect.size()>0:
					expecting=serverExpect[0]
				else:
					expecting=""

		if success==0:
			scanning=false

func onConnected(srvr):
	dlGui.set_text("Connected.")
	#serverExpect.append("time")
	#server.writestr("time\r\n")
	serverExpect.append("manifest")
	server.writestr("manifest\r\n")

func onConnFail():
	dlGui.set_text("Failed to connect to server.")

var dlFile=""
func start_download(name):
	dlFile=name
	blk_cur=0
	blk_cur_size=0
	blk_total=0
	blk_data_done=0
	blk_data_total=svrManifest[name]['size']
	blk_data.resize(0)
	serverExpect.append("head")
	server.writestr("get %s\r\n" % dlFile)

var assetsReady=false
var patch_todo=[]
func processResult(type,result):

	if type=='time':
		var worldTime=int(result)
		setWorldTime(worldTime)

	if type=='manifest':
		svrManifest.parse_json(result)
		var mfInfo
		var cliHash
		var cliFile=File.new()
		var srvHash
		var file
		for each in svrManifest:
			file="user://%s" % each
			mfInfo=svrManifest[each]
			srvHash=mfInfo['hash']
			if cliFile.file_exists(file):
				cliHash=cliFile.get_sha256(file)
			else:
				cliHash="".sha256_text()
			if cliHash!=srvHash:
				patch_todo.append(each)
		if patch_todo.size()==0:
			dlGui.set_text("Game is up to date.")
			server.writestr("quit\r\n")
			assetsReady=true
		else:
			start_download(patch_todo[0])

func processDownload(data,name):
	var sz=data.size()
	dlGui.set_text("Downloaded %0.02f KB of data" % [sz/1024.0])
	var f=File.new()
	f.open("user://"+name,File.WRITE)
	f.store_buffer(data)
	f.close()
	patch_todo.pop_front()
	if patch_todo.size()==0:
		server.writestr("quit\r\n")
		assetsReady=true
		dlGui.set_text("Patching finished.")
	else:
		start_download(patch_todo[0])

func onBlockNotify(bCur,bTot,dataCur,dataTot):
	# when block recevied
	# perhaps print progress bar or something
	var prog=dlFile+" "
	var cur=int(30*dataCur/dataTot)
	for i in range(cur):
		prog+="#"
	for i in range(30-cur):
		prog+="="
	dlGui.set_text(prog)

func onMapLoadChunk(quadCode,lyr,map,curVM):
	print("Load %s to layer[%d]: %s" % [quadCode,lyr,map])

var c_nonce
var s_nonce
var sendSeq=1
var recvSeq=0
var sessId=0
func onPacket(frame):
	var msg=frame['data']
	if msg.has('oper'):
		var op=msg['oper']

		if op=='report_world_time':
			setWorldTime(msg['time'])

		if op=='report_session':
			sessId=msg['id']
			recvSeq=msg['seq']
			s_nonce=msg['snonce']

var processState={}
var bgm_file=null
var fsDebounce=false
var startWorld=false
var startSession=false
var frame={}
var timeSync=0
func _process(delta):

	if processState.has('quitting') or \
		Input.is_action_pressed("user_quit"):
		get_tree().quit()

	if Input.is_action_pressed("fullscreen_toggle") and !fsDebounce:
		fsDebounce=true
		if OS.is_window_fullscreen():
			OS.set_window_fullscreen(false)
		else:
			OS.set_window_fullscreen(true)
	if !Input.is_action_pressed("fullscreen_toggle"):
		fsDebounce=false

	timeSync-=delta
	if timeSync<0:
		timeSync=15
		udp.put_var({'oper':'get_time'})

	while udp.get_available_packet_count()>0:
		frame.clear()
		frame['data']=udp.get_var()
		frame['addr']=udp.get_packet_ip()
		frame['port']=udp.get_packet_port()
		onPacket(frame)

	if assetsReady:
		
		if !startSession:
			startSession=true
			c_nonce=randi()
			udp.put_var({
				'oper'		:	'begin',
				'cnonce'	:	c_nonce
			})

		if !startWorld:
			startWorld=true
			camera.set_zoom(Vector2(1,1))
			userscreen.set_scale(Vector2(1,1))
			currentMap.recenter(0,0)
			world_over.set_hidden(false)
			world_rgn.set_hidden(false)
			timeGui.set_hidden(false)

		if bgm_file==null:
			bgm_file=load("user://bgm/concert.ogg")
			bgm.set_stream(bgm_file)
			bgm.play()

func _ready():
	set_process(true)
	OS.set_window_title("Omega Rising")

	# Make sure content dirs exist
	var e1=initialize_dir("user://world")
	var e2=initialize_dir("user://world/overworld")
	var e3=initialize_dir("user://world/regions")
	if e1!=OK or e2!=OK or e3!=OK:
		print("Unable to create map data directories. Exiting.")
		processState['quitting']=true
	e1=initialize_dir("user://gfx")
	e2=initialize_dir("user://sfx")
	e3=initialize_dir("user://bgm")
	if e1!=OK or e2!=OK or e3!=OK:
		print("Unable to create gfx/sound directories. Exiting.")
		processState['quitting']=true

	currentMap=get_node("Overworld/vmap")

	dlGui.set_text("Connecting to server...")
	server.connectToPeer("127.0.0.1",4000)
	udp.set_send_address("127.0.0.1",4000)
	udp.listen(4001)

	timeGui.set_hidden(true)
	world_over.set_hidden(true)
	world_rgn.set_hidden(true)
