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
				node_type[ob]=type
				node_tcount[type]+=1
				ob.set_title(title)
				ob.set_name(title)
				grid.add_child(ob)
				ob.set_show_close_button(true)
				ob.connect("close_request",self,"onNodeClose",[ob])
				callv("onMenu_%s" % type,[ob,vpos])
	# seocnd pass: set connections
	var rawcon=template['Template']['connections']
	var connections={}
	connections.parse_json(rawcon)
	print("Load: ",connections)
	for entry in connections['list']:
		print("  Conn: ",entry)
		grid.connect_node(entry['from'],entry['from_port'],entry['to'],entry['to_port'])

func onSave():
	var template={}
	template["Template"]={}
	template["Template"]["pos"]=finalNode.get_offset()
	var connections={'list':grid.get_connection_list()}
	print("Save: ",connections)
	template["Template"]["connections"]=connections.to_json()
	var type
	for type in menuLabels:
		template[type]={}
	var title
	var vpos
	for ob in node_type.keys():
		type=node_type[ob]
		title=ob.get_title()
		vpos=ob.get_offset()
		template[type][title]={}
		template[type][title]['pos']=vpos
	chrTpl.write("template",template)
	

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
