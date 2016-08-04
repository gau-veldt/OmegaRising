
extends Node

const EOL=RawArray([13,10])

onready var server=get_node("/root/Server")

func onProtoCommand(who,what):
	var cmd=what.to_lower()
	var ss=server.sessionState[who]
	var mfs=server.manifest
	var sxcvr=ss['xcvr']
	server.logMessage("Got command '%s' from peer %s:%s" % [what, ss['addr'], ss['port']])

	# client requests exit
	if cmd=='quit':
		sxcvr.disconnect()

	# client asks for game world time
	if cmd=='time':
		sxcvr.writestr(str(int(server.worldTime)))
		sxcvr.write(EOL)

	# client asks for asset/patch manifest
	if cmd=='manifest':
		sxcvr.writestr(mfs.to_json())
		sxcvr.write(EOL)

	# client asks for file
	if cmd=='get':
		sxcvr.writestr("No name\r\n")
	if cmd.substr(0,4)=='get ':
		var fs=File.new()
		var file=what.right(4)
		if file!="":
			if mfs.has(file):
				var sendF=File.new()
				var err=sendF.open("res://%s" % file,File.READ)
				ss['blk_todo']=sendF.get_len()
				ss['blk_done']=0
				ss['blk_file']=sendF
				ss['mode']="SEND"
			else:
				server.logMessage("%s get non-existant file: res://%s" % \
								  [str(who),file])
				sxcvr.writestr("Non-exist\r\n")
		else:
			sxcvr.writestr("No name\r\n")

var msg
var op
var nextSession=1
func onPeerMessage(frame):
	msg=frame['data']
	if msg.has('oper'):
		op=msg['oper']

		if op=='get_time':
			# get world time
			server.udp.set_send_address(frame['addr'],server.serverPort+1)
			server.udp.put_var({'oper':'report_world_time','time':int(server.worldTime)})

		if op=='begin':
			# establish a session
			# the 2-way nonces are an attempt to mitigate MITM replay attacks
			if msg.has('cnonce'):
				server.frameSession[nextSession]={}
				var frm=server.frameSession[nextSession]
				frm['seq']=1
				frm['rseq']=0
				frm['addr']=frame['addr']
				frm['snonce']=randi()
				frm['cnonce']=msg['cnonce']
				frm['idle']=0
				server.udp.set_send_address(frame['addr'],server.serverPort+1)
				server.udp.put_var({
					'oper'	:	'report_session',
					'id'	:	nextSession,
					'seq'	:	1,
					'rseq'	:	0,
					'snonce'	:	frm['snonce']
				})
				nextSession+=1

func _ready():
	pass
