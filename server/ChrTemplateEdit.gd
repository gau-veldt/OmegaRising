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
	ob.set_title("%s_%d" % [type,node_tcount[type]])
	grid.add_child(ob)
	ob.set_show_close_button(true)
	ob.connect("close_request",self,"onNodeClose",[ob])
	callv("onMenu_%s" % menuLabels[opt],[ob,nodeMenu.get_pos()])

func onNodeClose(ob):
	node_type.erase(ob)
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
	txt.set_name("")
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
	txt.set_name("")
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
	if template.has("Template"):
		tnode=template["Template"]
		vpos=persist.str2vec(tnode["pos"])
		finalNode.set_offset(vpos)

func onSave():
	var template={}
	template["Template"]={}
	template["Template"]["pos"]=finalNode.get_offset()
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
