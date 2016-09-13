extends Control

onready var server=get_node("/root/Peer")
onready var persist=get_node("/root/persist")
onready var grid=get_node("view")
onready var finalNode=get_node("view/Character")
onready var nodeMenu=get_node("node_menu")
onready var btnSave=get_node("save")
onready var btnRevert=get_node("revert")

const PORT_NULL=0
const PORT_OPTION=1
const PORT_ATTR=2
const PORT_RESULT=3
const PORT_COND=4
const COLOR_NULL=Color(.5,0,0)
const COLOR_OPTION=Color(.25,.75,.5)
const COLOR_ATTR=Color(.25,.5,.75)
const COLOR_RESULT=Color(.75,.75,.25)
const COLOR_COND=Color(.5,.75,.25)
var node_type={}
var node_tcount={}

var chrTpl=null

func countforType(typeKey):
	var tcount=0
	for each in node_type.keys():
		if node_type[each]==typeKey:
			tcount+=1
	return tcount

func title2index(title):
	var ary=title.split("_")
	return int(ary[1])

func make_title(type,idx):
	return "%s_%d" % [type,idx]

func renumberForDelete(node):
	# rename node to delete so it is
	# highest-numbered after renumbering
	# all nodes of node to delete's type
	var type=node_type[node]
	var tcount=node_tcount[type]
	var gap=title2index(node.get_title())
	if gap!=tcount:
		# resetting title as if object was
		# being created rather than deleted
		# makes it highest-numbered
		var high=tcount+1
		var hi_title=make_title(type,high)
		node.set_title(hi_title)
		var bytitle={}
		for each in node_type:
			if node_type[each]==type:
				bytitle[each.get_title()]=each
		var t_old
		var t_new
		var ob
		for space in range(gap,high):
			t_old=make_title(type,space+1)
			t_new=make_title(type,space)
			ob=bytitle[t_old]
			ob.set_title(t_new)

func onPopupNodeMenu(pos):
	nodeMenu.set_pos(pos)
	nodeMenu.popup()

var menuLabels=[
	'Option',
	'ChooseOne','ChooseMulti',
	'Include','Exclude',
	'Test',
	'String',
	'IntRange','FloatRange'
]
func onNodeMenuChoice(opt):
	var ob=GraphNode.new()
	var type=menuLabels[opt]
	node_type[ob]=type
	node_tcount[type]+=1
	ob.set_title(make_title(type,node_tcount[type]))
	ob.set_name(ob.get_title())
	grid.add_child(ob)
	ob.set_show_close_button(true)
	ob.connect("close_request",self,"onNodeClose",[ob])
	callv("onMenu_%s" % menuLabels[opt],[ob,nodeMenu.get_pos()])

func onNodeClose(ob):
	renumberForDelete(ob)
	var type=node_type[ob]
	node_type.erase(ob)
	node_tcount[type]-=1
	ob.queue_free()

func onMenu_Option(ob,pos):
	var txt=LineEdit.new()
	txt.set_name("caption")
	txt.set_custom_minimum_size(Vector2(160,0))
	ob.set_custom_minimum_size(Vector2(0,64))
	ob.add_child(txt)
	ob.set_offset(pos)
	ob.set_slot(0,false,PORT_NULL,COLOR_NULL,true,PORT_OPTION,COLOR_OPTION)
	txt.set_tooltip("Enter label for this option.\nLabels should be unique.")

func onMenu_ChooseOne(ob,pos):
	var txt=LineEdit.new()
	txt.set_name("caption")
	txt.set_custom_minimum_size(Vector2(160,0))
	ob.set_custom_minimum_size(Vector2(0,64))
	ob.add_child(txt)
	txt=Label.new()
	ob.add_child(txt)
	ob.set_offset(pos)
	ob.set_slot(0,true,PORT_OPTION,COLOR_OPTION,true,PORT_ATTR,COLOR_ATTR)
	ob.set_slot(1,true,PORT_COND,COLOR_COND,false,PORT_NULL,COLOR_NULL)
	txt.set_tooltip("Enter name of attribute unique to all other attributes.\n"+\
		"Attribute allows selecting exactly one of the connected options.")

func onMenu_ChooseMulti(ob,pos):
	var txt=LineEdit.new()
	txt.set_name("caption")
	txt.set_custom_minimum_size(Vector2(160,0))
	ob.set_custom_minimum_size(Vector2(0,64))
	ob.add_child(txt)
	txt=Label.new()
	ob.add_child(txt)
	ob.set_offset(pos)
	ob.set_slot(0,true,PORT_OPTION,COLOR_OPTION,true,PORT_ATTR,COLOR_ATTR)
	ob.set_slot(1,true,PORT_COND,COLOR_COND,false,PORT_NULL,COLOR_NULL)
	txt.set_tooltip("Enter name of attribute unique to all other attributes.\n"+\
		"Attribute allows selecting zero or more of the connected options.")

func onMenu_Include(ob,pos):
	var txt=Label.new()
	txt.set_text("options")
	ob.add_child(txt)
	txt=Label.new()
	txt.set_text("when")
	ob.add_child(txt)
	ob.set_offset(pos)
	ob.set_custom_minimum_size(Vector2(160,64))
	ob.set_slot(0,true,PORT_OPTION,COLOR_OPTION,true,PORT_COND,COLOR_COND)
	ob.set_slot(1,true,PORT_RESULT,COLOR_RESULT,false,PORT_NULL,COLOR_NULL)
	ob.set_tooltip("Includes all options input to 'options' if all results input to 'when' are true.")

func onMenu_Exclude(ob,pos):
	var txt=Label.new()
	txt.set_text("options")
	ob.add_child(txt)
	txt=Label.new()
	txt.set_text("when")
	ob.add_child(txt)
	ob.set_offset(pos)
	ob.set_custom_minimum_size(Vector2(160,64))
	ob.set_slot(0,true,PORT_OPTION,COLOR_OPTION,true,PORT_COND,COLOR_COND)
	ob.set_slot(1,true,PORT_RESULT,COLOR_RESULT,false,PORT_NULL,COLOR_NULL)
	ob.set_tooltip("Excludes all options input to 'options' if all results input to 'when' are true.")

func onTestToggle(active,host):
	var rslt=host.get_node("result")
	if active:
		rslt.set_text("unselected")
	else:
		rslt.set_text("selected")
func onMenu_Test(ob,pos):
	var txt=Label.new()
	txt.set_text("attr")
	ob.add_child(txt)
	txt=Label.new()
	txt.set_text("option")
	ob.add_child(txt)
	txt=Label.new()
	txt.set_name("result")
	txt.set_text("selected")
	ob.add_child(txt)
	var neg=Button.new()
	neg.set_name("btnInvert")
	neg.set_toggle_mode(true)
	neg.set_text("Invert")
	neg.connect("toggled",self,"onTestToggle",[ob])
	ob.add_child(neg)
	ob.set_offset(pos)
	ob.set_custom_minimum_size(Vector2(160,96))
	ob.set_slot(0,true,PORT_ATTR,COLOR_ATTR,false,PORT_NULL,COLOR_NULL)
	ob.set_slot(1,true,PORT_OPTION,COLOR_OPTION,false,PORT_NULL,COLOR_NULL)
	ob.set_slot(2,false,PORT_NULL,COLOR_NULL,true,PORT_RESULT,COLOR_RESULT)
	ob.set_tooltip("Tests specified attribute to have specified option selected, with optional negation.")

func onMenu_String(ob,pos):
	var txt=LineEdit.new()
	txt.set_name("caption")
	txt.set_custom_minimum_size(Vector2(160,0))
	ob.set_custom_minimum_size(Vector2(0,64))
	ob.add_child(txt)
	ob.set_offset(pos)
	ob.set_slot(0,false,PORT_NULL,COLOR_NULL,true,PORT_ATTR,COLOR_ATTR)
	txt.set_tooltip("Enter unique name of this string attribute.")

func onMenu_IntRange(ob,pos):
	var txt=LineEdit.new()
	txt.set_name("caption")
	txt.set_custom_minimum_size(Vector2(160,0))
	txt.set_tooltip("Enter unique name of this integer attribute.")
	ob.add_child(txt)
	txt=LineEdit.new()
	txt.set_name("min")
	txt.set_custom_minimum_size(Vector2(160,0))
	txt.set_tooltip("Enter minimum of this integer attribute.")
	ob.add_child(txt)
	txt=LineEdit.new()
	txt.set_name("max")
	txt.set_custom_minimum_size(Vector2(160,0))
	txt.set_tooltip("Enter maximum of this integer attribute.")
	ob.add_child(txt)
	ob.set_custom_minimum_size(Vector2(0,64))
	ob.set_offset(pos)
	ob.set_slot(0,false,PORT_NULL,COLOR_NULL,true,PORT_ATTR,COLOR_ATTR)

func onMenu_FloatRange(ob,pos):
	var txt=LineEdit.new()
	txt.set_name("caption")
	txt.set_custom_minimum_size(Vector2(160,0))
	txt.set_tooltip("Enter unique name of this decimal attribute.")
	ob.add_child(txt)
	txt=LineEdit.new()
	txt.set_name("min")
	txt.set_custom_minimum_size(Vector2(160,0))
	txt.set_tooltip("Enter minimum of this decimal attribute.")
	ob.add_child(txt)
	txt=LineEdit.new()
	txt.set_name("max")
	txt.set_custom_minimum_size(Vector2(160,0))
	txt.set_tooltip("Enter maximum of this decimal attribute.")
	ob.add_child(txt)
	ob.set_custom_minimum_size(Vector2(0,64))
	ob.set_offset(pos)
	ob.set_slot(0,false,PORT_NULL,COLOR_NULL,true,PORT_ATTR,COLOR_ATTR)

var nodeCodecs={
	'Option':		'Named',
	'ChooseOne':	'Named',
	'ChooseMulti':	'Named',
	'Include':		'',
	'Exclude':		'',
	'Test':			'Tester',
	'String':		'Named',
	'IntRange':		'NamedInt',
	'FloatRange':	'NamedFloat'
}
func encodeTester(ob):
	return {
		'inverted':ob.get_node("result").get_text()=="unselected"
	}
func decodeTester(ob,data):
	if data['inverted']:
		ob.get_node("btnInvert").set_pressed(true)
		ob.get_node("result").set_text("unselected")
	else:
		ob.get_node("btnInvert").set_pressed(false)
		ob.get_node("result").set_text("selected")

func encodeNamed(ob):
	return {
		'name':ob.get_node("caption").get_text()
	}
func decodeNamed(ob,data):
	ob.get_node("caption").set_text(str(data['name']))

func encodeNamedFloat(ob):
	return {
		'name':ob.get_node("caption").get_text(),
		'min':float(ob.get_node("min").get_text()),
		'max':float(ob.get_node("max").get_text())
	}
func decodeNamedFloat(ob,data):
	ob.get_node("caption").set_text(str(data['name']))
	ob.get_node("min").set_text(str(float(data['min'])))
	ob.get_node("max").set_text(str(float(data['max'])))

func encodeNamedInt(ob):
	return {
		'name':ob.get_node("caption").get_text(),
		'min':int(ob.get_node("min").get_text()),
		'max':int(ob.get_node("max").get_text())
	}
func decodeNamedInt(ob,data):
	ob.get_node("caption").set_text(str(data['name']))
	ob.get_node("min").set_text(str(int(data['min'])))
	ob.get_node("max").set_text(str(int(data['max'])))

func onAttachNode(org,org_slot,dest,dest_slot):
	var org_ob=grid.get_node(org)
	var org_type=node_type[org_ob]
	var dest_ob=grid.get_node(dest)
	var dest_type=-1
	if node_type.has(dest_ob):
		dest_type=node_type[dest_ob]
	else:
		dest_type="Template"
	print("Attach: %s %s %s %s %s %s" % [org,org_type,org_slot,dest,dest_type,dest_slot])
	grid.connect_node(org,org_slot,dest,dest_slot)

func onDetachNode(org,org_slot,dest,dest_slot):
	var org_ob=grid.get_node(org)
	var org_type=node_type[org_ob]
	var dest_ob=grid.get_node(dest)
	var dest_type=-1
	if node_type.has(dest_ob):
		dest_type=node_type[dest_ob]
	else:
		dest_type="Template"
	print("Detach: %s %s %s %s %s %s" % [org,org_type,org_slot,dest,dest_type,dest_slot])
	grid.disconnect_node(org,org_slot,dest,dest_slot)

func onRevert():
	# clear out the current graph
	var clist=grid.get_connection_list()
	for conn in clist:
		grid.disconnect_node(conn['from'],conn['from_port'],conn['to'],conn['to_port'])
	# mangle nodenames since queue_free only happens after
	# we're finished and thus the old GraphNodes won't yet be gone
	var gonzo=1
	for each in node_type:
		each.set_name("*gonzo*%d*" % gonzo)
		gonzo+=1
	finalNode.set_offset(Vector2(64,64))
	var nodes=node_type.keys()
	for each in nodes:
		if each!=finalNode:
			node_type.erase(each)
			each.queue_free()
	for each in menuLabels:
		node_tcount[each]=0

	# revert to CharacterTemplate
	var template=chrTpl.read("template")
	var tnode
	var vpos
	var ob
	var data={}
	# first pass: generate GraphNodes
	for type in template.keys():
		if type=="Template":
			tnode=template["Template"]
			vpos=persist.str2vec(tnode['pos'])
			finalNode.set_offset(vpos)
		else:
			for title in template[type]:
				tnode=template[type][title]
				ob=GraphNode.new()
				vpos=persist.str2vec(tnode['pos'])
				data.parse_json(tnode['data'])
				node_type[ob]=type
				node_tcount[type]+=1
				ob.set_title(title)
				ob.set_name(title)
				grid.add_child(ob)
				ob.set_show_close_button(true)
				ob.connect("close_request",self,"onNodeClose",[ob])
				callv("onMenu_%s" % type,[ob,vpos])
				if nodeCodecs[type]!='':
					callv("decode%s" % nodeCodecs[type],[ob,data])
	# seocnd pass: set connections
	var rawcon=template['Template']['connections']
	var connections={}
	connections.parse_json(rawcon)
	for entry in connections['list']:
		grid.connect_node(entry['from'],entry['from_port'],entry['to'],entry['to_port'])

func onSave():
	var template={}
	template["Template"]={}
	template["Template"]["pos"]=finalNode.get_offset()
	var connections={'list':grid.get_connection_list()}
	template["Template"]["connections"]=connections.to_json()
	var type
	for type in menuLabels:
		template[type]={}
	var title
	var vpos
	var data
	for ob in node_type.keys():
		data={}
		type=node_type[ob]
		title=ob.get_title()
		vpos=ob.get_offset()
		if nodeCodecs[type]=='Named':
			data=encodeNamed(ob)
		if nodeCodecs[type]=='NamedFloat':
			data=encodeNamedFloat(ob)
		if nodeCodecs[type]=='NamedInt':
			data=encodeNamedInt(ob)
		if nodeCodecs[type]=='Tester':
			data=encodeTester(ob)
		template[type][title]={}
		template[type][title]['pos']=vpos
		template[type][title]['data']=data.to_json()
	chrTpl.write("template",template)
	convertGraph()

var theTemplate={}
func getTemplate():
	return theTemplate
func convertGraph():
	var edges=grid.get_connection_list()
	var type
	var name
	var blocks={}
	theTemplate.clear()
	theTemplate['Attributes']={}
	for ob in node_type.keys():
		type=node_type[ob]
		name=ob.get_title()
		blocks[name]={'type':type,'ob':ob,'in':{},'out':{}}
	for edge in edges:
		if edge['to']!='Character':
			if !blocks[edge['to']]['in'].has(edge['to_port']):
				blocks[edge['to']]['in'][edge['to_port']]=[{edge['from']:edge['from_port']}]
			else:
				blocks[edge['to']]['in'][edge['to_port']].append({edge['from']:edge['from_port']})
		if edge['from']!='Character':
			if !blocks[edge['from']]['out'].has(edge['from_port']):
				blocks[edge['from']]['out'][edge['from_port']]=[{edge['to']:edge['to_port']}]
			else:
				blocks[edge['from']]['out'][edge['from_port']].append({edge['to']:edge['to_port']})
	var attr
	var attr_name
	var attr_def
	for edge in edges:
		if edge['to']=='Character':
			if edge['to_port']==0:
				attr=convertAttribute(edge,blocks)
				attr_name=attr.keys()[0]
				attr_def=attr[attr_name]
				theTemplate['Attributes'][attr_name]=attr_def
	print("chargen template: ",theTemplate.to_json())
func convertAttribute(attr,blocks):
	var cvt={}
	var what=attr['from']
	var kind=blocks[what]['type']
	var who=blocks[what]['ob']
	var name=who.get_node('caption').get_text()
	cvt[name]={'type':kind}
	if kind in ['ChooseOne','ChooseMulti']:
		cvt[name]['options']=convertOptions(what,blocks)
	return cvt
func convertOptions(attr,blocks):
	var cvt=[]
	var opt
	var opt_block
	var opt_node
	var opt_name
	var sources=blocks[attr]['in']
	if sources.has(0):
		for pair in sources[0]:
			opt=pair.keys()[0]
			opt_block=blocks[opt]
			opt_node=opt_block['ob']
			opt_name=opt_node.get_node("caption").get_text()
			cvt.append({'always':opt_name})
	if sources.has(1):
		for pair in sources[1]:
			opt=pair.keys()[0]
			cvt.append(convertConditionalOption(opt,blocks))
	return cvt
func convertConditionalOption(opt,blocks):
	var cvt={}
	var opt_block=blocks[opt]
	var opt_kind=opt_block['type']
	var tests=[]
	var test_attr
	var test_opt
	var cond_opts=[]
	if opt_block['in'].has(0):
		var blk
		var blk_node
		var opt_name
		for pair in opt_block['in'][0]:
			blk=blocks[pair.keys()[0]]
			blk_node=blk['ob']
			opt_name=blk_node.get_node('caption').get_text()
			cond_opts.append(opt_name)
	cvt[opt_kind]=cond_opts
	var tests=[false]
	if opt_block['in'].has(1):
		tests=[]
		var test
		for pair in opt_block['in'][1]:
			test=pair.keys()[0]
			tests.append(convertTest(test,blocks))
	cvt['when']=tests
	return cvt
func convertTest(test,blocks):
	var cond={}
	var test_blk=blocks[test]
	var test_node=test_blk['ob']
	var invert=test_node.get_node('result').get_text()=="unselected"
	var test_attr=null
	var test_opt=null
	var inputs=test_blk['in']
	if inputs.has(0):
		var attr_blk=blocks[inputs[0][0].keys()[0]]
		var attr_node=attr_blk['ob']
		test_attr=attr_node.get_node("caption").get_text()
	if inputs.has(1):
		var opt_blk=blocks[inputs[1][0].keys()[0]]
		var opt_node=opt_blk['ob']
		test_opt=opt_node.get_node("caption").get_text()
	if test_attr==null or test_opt==null:
		cond=false
	else:
		cond['not']=invert
		cond['attr']=test_attr
		cond['option']=test_opt
	return cond

func _ready():
	for each in menuLabels:
		node_tcount[each]=0

	if !persist.index_bytype.has('CharacterTemplate'):
		var ob=persist.spawn("CharacterTemplate")
		var props=ob.read("props")
		props['created']="[%08x:%03d] " % [OS.get_unix_time(),OS.get_ticks_msec()%1000]
		ob.write('props',props)
	var forms=persist.index_bytype['CharacterTemplate'].get_children()
	chrTpl=forms[0]

	grid.set_right_disconnects(true)
	grid.connect("popup_request",self,"onPopupNodeMenu")
	grid.connect("connection_request",self,"onAttachNode")
	grid.connect("disconnection_request",self,"onDetachNode")
	nodeMenu.connect("item_pressed",self,"onNodeMenuChoice")
	btnRevert.connect("pressed",self,"onRevert")
	btnSave.connect("pressed",self,"onSave")

	finalNode.set_slot(0,true,PORT_ATTR,COLOR_ATTR,false,PORT_NULL,COLOR_NULL)
	onRevert()
	convertGraph()
