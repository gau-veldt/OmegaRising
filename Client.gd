
extends Node

# reference to the object lobby
onready var lobby=get_node("/root/lobby")

onready var dir=Directory.new()
onready var dayAnim=get_node("Camera/Decoration/DayNightCycle")

# asset related vars
var assetManifest={}
const dl_head_size=25
const mfFile="user://manifest"
var server=StreamPeerTCP.new()
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

var buf
var head
var blk_size
var dl
var as
var processState={}
func _process(delta):
	if processState.has('quitting'):
		get_tree().quit()

	if processState.has('dl'):
		dl=processState['dl']
		if !dl.has('state'):
			dl['state']='head'
			dl['elapsed']=0.0
			dl['xfer_tot']=0
			dl['gui']=get_node("Camera/Decoration/HUD/DL")
		else:
			dl['elapsed']+=delta
		if dl['state']=='head':
			if server.get_available_bytes()>=dl_head_size:
				head=server.get_string(dl_head_size)
				dl['cur']=int(head.substr(5,6))
				dl['last']=int(head.substr(12,6))
				dl['bsize']=int(head.substr(19,5))
				dl['state']='blk'
		if dl['state']=='blk':
			blk_size=dl['bsize']
			if server.get_available_bytes()>=blk_size:
				dl['xfer_tot']+=blk_size
				buf=server.get_data(blk_size)
				dl['file'].seek_end()
				dl['file'].store_buffer(buf[1])
				dl['state']='eol'
				dl['gui'].set_text("%06d/%06d (%05d) %03d%%" % \
							       [dl['cur'],dl['last'], blk_size, \
								   int(100.0*dl['cur']/dl['last'])])
		if dl['state']=='eol':
			if server.get_available_bytes()>=2:
				server.get_string(2)
				if dl['cur']==dl['last']:
					dl['state']='done'
				else:
					dl['state']='head'
		if dl['state']=='done':
			dl['gui'].set_text("%s: %0.2f KB in %0.2f seconds (%0.2f KB/sec)" % [\
								dl['name'],dl['xfer_tot']/1024.0,dl['elapsed'],\
								(dl['xfer_tot']/1024.0)/dl['elapsed']])
			dl['state']='dead'
			server.put_utf8_string("quit\r\n")
			server.disconnect()
			var fnm="user://"+dl['name']
			as=ResourceLoader.load(fnm)
			get_node("bgm").set_stream(as)
			get_node("bgm").play()
			dl=null
			processState.erase('dl')

func _ready():
	# Turn on _process
	set_process(true)
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
	setWorldTime(0*60) # 0700 (7 AM)
	
	var inp=""
	var ich=""
	var dl
	var dfile
	var err=-1
	print("Connecting to server...")
	err=server.connect("127.0.0.1",4000)
	if err==OK:
		print("Connected.")
		server.put_utf8_string("manifest\r\n")
		while ich!='\n':
			ich=server.get_string(1)
			inp+=ich
		svrManifest.parse_json(inp)
		dfile=svrManifest.keys()[0]
		processState['dl']={}
		dl=processState['dl']
		dl['file']=File.new()
		dl['file'].open("user://%s" % dfile, File.WRITE)
		dl['cur']=0
		dl['last']=-1
		dl['name']=dfile
		server.put_utf8_string("get %s\r\n" % dfile)
	else:
		# connect failed, no server
		print("Connect Failed (err=%d)" % err)
